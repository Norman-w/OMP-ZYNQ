/**
 *****************************************************************************
 * 网络初始化模块 - 配置YT8531 PHY和固定IP
 *****************************************************************************
 *
 * @File   : network_init.c
 * @By     : Norman
 * @Version: V1.0
 * @Date   : 2024
 * @Forum  : OMP BY NORMAN (WIP) Basedon Xiaomeige
 *****************************************************************************
**/

#include "network_init.h"
#include "xil_printf.h"
#include "xparameters.h"
#include "sleep.h"

#if defined (__arm__) || defined (__aarch64__)
#include "lwip/netif.h"
#include "lwip/ip_addr.h"
#include "lwip/ip4_addr.h"
#include "lwip/mem.h"
#include "lwip/icmp.h"
#include "lwip/raw.h"
#include "lwip/inet_chksum.h"
#include "lwip/ip.h"
#include "lwip/pbuf.h"
#include "lwip/err.h"
#include "netif/xadapter.h"
#include "netif/xtopology.h"
#include "xemacps.h"

// YT8531 PHY寄存器定义
#define YT8531_PHY_ID1_REG           0x02    // PHY ID寄存器1
#define YT8531_PHY_ID2_REG           0x03    // PHY ID寄存器2
#define YT8531_BMCR_REG              0x00    // 基本模式控制寄存器
#define YT8531_BMSR_REG              0x01    // 基本模式状态寄存器
#define YT8531_PHYSR_REG             0x11    // PHY状态寄存器
#define YT8531_ANAR_REG              0x04    // 自动协商通告寄存器
#define YT8531_ANLPAR_REG            0x05    // 自动协商链路伙伴能力寄存器
#define YT8531_ANER_REG              0x06    // 自动协商扩展寄存器
#define YT8531_GBECTRL_REG           0x0E    // 千兆控制寄存器

// YT8531寄存器位定义
#define BMCR_RESET                   0x8000  // 软件复位
#define BMCR_AN_ENABLE               0x1000  // 自动协商使能
#define BMCR_DUPLEX_MODE             0x0100  // 全双工模式
#define BMCR_SPEED_SELECT            0x0040  // 速度选择 (1=1000M, 0=10/100M)
#define BMCR_SPEED_1000              0x0040  // 1000Mbps

#define ANAR_PAUSE                   0x0400  // 暂停能力
#define ANAR_100FULL                 0x0100  // 100M全双工
#define ANAR_100HALF                 0x0080  // 100M半双工
#define ANAR_10FULL                  0x0040  // 10M全双工
#define ANAR_10HALF                  0x0020  // 10M半双工
#define ANAR_SELECTOR                0x0001  // 选择器字段

// 千兆能力
#define GBECTRL_1000FULL             0x0200  // 1000M全双工
#define GBECTRL_1000HALF             0x0100  // 1000M半双工

// 固定IP配置
#define NETWORK_FIXED_IP_ADDR        "192.168.0.123"
#define NETWORK_FIXED_NETMASK        "255.255.255.0"
#define NETWORK_FIXED_GATEWAY        "192.168.0.1"

// 网络监测配置
#define NETWORK_MONITOR_TARGET_IP    "192.168.0.3"
#define NETWORK_MONITOR_INTERVAL     500  // 5秒 = 500 * 10ms (定时器每10ms触发一次)

// 全局变量
static struct netif *g_netif = NULL;
static int g_network_init_status = 0;  // 0=未初始化, 1=成功, -1=失败
static struct raw_pcb *g_ping_pcb = NULL;
static ip_addr_t g_ping_target;
static int g_ping_counter = 0;
static int g_ping_success_count = 0;
static int g_ping_fail_count = 0;
static int g_network_monitor_counter = 0;

/**
 * @brief 快速配置YT8531 PHY为千兆模式（非阻塞，快速返回）
 * @param emacps_instance EMACPS实例指针
 * @return 0=成功, -1=失败
 */
static int configure_yt8531_gigabit_mode(XEmacPs *emacps_instance)
{
    u16 phy_reg;
    u16 phy_addr = 0;  // 通常PHY地址为0或1，根据硬件设计
    int status = 0;

    xil_printf("[NET] 开始配置YT8531 PHY为千兆模式...\n\r");

    // 快速检测PHY（只检查前几个地址，避免长时间阻塞）
    for (phy_addr = 0; phy_addr < 4; phy_addr++) {
        status = XEmacPs_PhyRead(emacps_instance, phy_addr, YT8531_PHY_ID1_REG, &phy_reg);
        if (status == XST_SUCCESS) {
            xil_printf("[NET] 检测到PHY，地址: 0x%02X\n\r", phy_addr);
            break;
        }
    }

    if (phy_addr >= 4) {
        xil_printf("[NET] 警告: 未找到PHY芯片，跳过配置\n\r");
        return -1;
    }

    // 快速配置：只设置基本参数，不等待结果
    // 读取当前BMCR值
    status = XEmacPs_PhyRead(emacps_instance, phy_addr, YT8531_BMCR_REG, &phy_reg);
    if (status != XST_SUCCESS) {
        xil_printf("[NET] 警告: 读取BMCR寄存器失败，跳过PHY配置\n\r");
        return -1;
    }

    // 配置基本模式控制寄存器：使能自动协商，千兆模式
    phy_reg = BMCR_AN_ENABLE | BMCR_SPEED_1000;
    status = XEmacPs_PhyWrite(emacps_instance, phy_addr, YT8531_BMCR_REG, phy_reg);
    if (status != XST_SUCCESS) {
        xil_printf("[NET] 警告: 写入BMCR寄存器失败\n\r");
        return -1;
    }

    // 配置自动协商通告寄存器：支持10M/100M/1000M全双工
    phy_reg = ANAR_SELECTOR | ANAR_10HALF | ANAR_10FULL | 
              ANAR_100HALF | ANAR_100FULL | ANAR_PAUSE;
    status = XEmacPs_PhyWrite(emacps_instance, phy_addr, YT8531_ANAR_REG, phy_reg);
    if (status != XST_SUCCESS) {
        xil_printf("[NET] 警告: 写入ANAR寄存器失败\n\r");
        // 继续执行，不返回错误
    }

    // 配置千兆控制寄存器：支持1000M全双工和半双工
    phy_reg = GBECTRL_1000HALF | GBECTRL_1000FULL;
    status = XEmacPs_PhyWrite(emacps_instance, phy_addr, YT8531_GBECTRL_REG, phy_reg);
    if (status != XST_SUCCESS) {
        // 某些PHY可能没有此寄存器，忽略错误
    }

    xil_printf("[NET] YT8531 PHY配置完成（异步协商中）\n\r");
    return 0;
}

/**
 * @brief 初始化网络接口并设置固定IP
 * @return 0=成功, -1=失败
 */
int network_init(void)
{
    ip_addr_t ipaddr, netmask, gw;
    static struct netif netif_struct;  // 使用静态分配，避免内存管理问题
    struct netif *netif = &netif_struct;
    XEmacPs *emacps_instance;
    int status;
    unsigned char mac_ethernet_address[] = {0x00, 0x0a, 0x35, 0x00, 0x01, 0x02};

    xil_printf("\n\r");
    xil_printf("========================================\n\r");
    xil_printf("[NET] 开始网络初始化...\n\r");
    xil_printf("========================================\n\r");

    // 检查是否已经初始化
    if (g_network_init_status == 1) {
        xil_printf("[NET] 网络已经初始化，跳过\n\r");
        return 0;
    }

    // 初始化lwIP
    xil_printf("[NET] 初始化lwIP协议栈...\n\r");
    lwip_raw_init();

    // 解析IP地址
    xil_printf("[NET] 配置固定IP地址: %s/%s\n\r", 
               NETWORK_FIXED_IP_ADDR, NETWORK_FIXED_NETMASK);
    
    if (ip4addr_aton(NETWORK_FIXED_IP_ADDR, &ipaddr) == 0) {
        xil_printf("[NET] 错误: IP地址格式无效: %s\n\r", NETWORK_FIXED_IP_ADDR);
        g_network_init_status = -1;
        xil_printf("[NET] 网络初始化失败，但不影响示波器功能\n\r");
        return -1;
    }

    if (ip4addr_aton(NETWORK_FIXED_NETMASK, &netmask) == 0) {
        xil_printf("[NET] 错误: 子网掩码格式无效: %s\n\r", NETWORK_FIXED_NETMASK);
        g_network_init_status = -1;
        xil_printf("[NET] 网络初始化失败，但不影响示波器功能\n\r");
        return -1;
    }

    if (ip4addr_aton(NETWORK_FIXED_GATEWAY, &gw) == 0) {
        xil_printf("[NET] 错误: 网关地址格式无效: %s\n\r", NETWORK_FIXED_GATEWAY);
        g_network_init_status = -1;
        xil_printf("[NET] 网络初始化失败，但不影响示波器功能\n\r");
        return -1;
    }

    // 获取网络接口
    xil_printf("[NET] 添加网络接口...\n\r");
    
    // 获取EMACPS基地址
    UINTPTR mac_baseaddr = xtopology[0].emac_baseaddr;
    xil_printf("[NET] EMAC基地址: 0x%08X\n\r", mac_baseaddr);

    // 添加网络接口
    netif = xemac_add(netif, &ipaddr, &netmask, &gw,
                      mac_ethernet_address, mac_baseaddr);
    
    if (netif == NULL) {
        xil_printf("[NET] 错误: 添加网络接口失败\n\r");
        g_network_init_status = -1;
        xil_printf("[NET] 网络初始化失败，但不影响示波器功能\n\r");
        return -1;
    }

    g_netif = netif;

    // 设置网络接口为默认接口
    netif_set_default(netif);

    // 使能网络接口
    netif_set_up(netif);

    xil_printf("[NET] 网络接口已添加并启用\n\r");

    // PHY配置暂时跳过，避免阻塞启动
    // 注意：PHY配置可以在系统稳定后通过定时器回调异步进行
    // 或者通过lwIP的自动链路检测功能自动处理
    xil_printf("[NET] 注意: PHY配置将在后台自动进行，不阻塞启动\n\r");

    // 打印网络配置信息（不等待链路建立）
    xil_printf("[NET] 网络配置信息:\n\r");
    xil_printf("[NET]   IP地址: %s\n\r", ip4addr_ntoa(&netif->ip_addr));
    xil_printf("[NET]   子网掩码: %s\n\r", ip4addr_ntoa(&netif->netmask));
    xil_printf("[NET]   网关: %s\n\r", ip4addr_ntoa(&netif->gw));
    xil_printf("[NET]   MAC地址: %02X:%02X:%02X:%02X:%02X:%02X\n\r",
               netif->hwaddr[0], netif->hwaddr[1], netif->hwaddr[2],
               netif->hwaddr[3], netif->hwaddr[4], netif->hwaddr[5]);
    xil_printf("[NET] 注意: 网络链路将在后台自动协商建立\n\r");

    g_network_init_status = 1;
    xil_printf("========================================\n\r");
    xil_printf("[NET] 网络初始化完成 (异步模式)\n\r");
    xil_printf("========================================\n\r");
    xil_printf("\n\r");
    
    // 初始化网络监测（ping功能）
    network_monitor_init();

    return 0;
}

/**
 * @brief 获取网络初始化状态
 * @return 1=成功, -1=失败, 0=未初始化
 */
int network_get_init_status(void)
{
    return g_network_init_status;
}

/**
 * @brief 获取网络接口指针
 * @return 网络接口指针，失败返回NULL
 */
struct netif* network_get_netif(void)
{
    return g_netif;
}

/**
 * @brief ICMP ping接收回调函数
 */
static u8_t ping_recv(void *arg, struct raw_pcb *pcb, struct pbuf *p, const ip_addr_t *addr)
{
    struct icmp_echo_hdr *iecho;
    u8_t icmp_type;
    
    if (p->tot_len < (IP_HLEN + sizeof(struct icmp_echo_hdr))) {
        pbuf_free(p);
        return 0;
    }
    
    // 跳过IP头
    if (pbuf_header(p, -IP_HLEN) != 0) {
        pbuf_free(p);
        return 0;
    }
    
    iecho = (struct icmp_echo_hdr *)p->payload;
    icmp_type = ICMPH_TYPE(iecho);
    
    // 检查是否是ICMP ECHO REPLY (类型0)
    if (icmp_type == 0) {  // ICMP_ER (Echo Reply)
        // 检查ID和序列号是否匹配
        if ((iecho->id == PING_ID) && (iecho->seqno == htons(PING_SEQNO))) {
            // Ping成功
            g_ping_success_count++;
            xil_printf("[NET] Ping %s 成功\n\r", NETWORK_MONITOR_TARGET_IP);
            pbuf_free(p);
            return 1;  // 吃掉这个包
        }
    }
    
    // 恢复IP头
    pbuf_header(p, IP_HLEN);
    pbuf_free(p);
    return 0;
}

/**
 * @brief 发送ICMP ping请求
 * @return 0=成功, -1=失败
 */
static int ping_send(void)
{
    struct pbuf *p;
    struct icmp_echo_hdr *iecho;
    size_t ping_size = 32;  // ping数据包大小
    
    if (g_ping_pcb == NULL || g_netif == NULL) {
        return -1;
    }
    
    // 检查网络接口是否就绪
    if (!netif_is_up(g_netif) || !netif_is_link_up(g_netif)) {
        return -1;
    }
    
    // 分配pbuf
    p = pbuf_alloc(PBUF_IP, ping_size, PBUF_RAM);
    if (p == NULL) {
        return -1;
    }
    
    if (p->len < ping_size) {
        pbuf_free(p);
        return -1;
    }
    
    // 填充ICMP echo请求
    iecho = (struct icmp_echo_hdr *)p->payload;
    ICMPH_TYPE_SET(iecho, ICMP_ECHO);  // ICMP_ECHO = 8
    ICMPH_CODE_SET(iecho, 0);
    iecho->chksum = 0;
    iecho->id = PING_ID;
    iecho->seqno = htons(PING_SEQNO);
    
    // 填充数据
    size_t data_len = ping_size - sizeof(struct icmp_echo_hdr);
    char *data_ptr = (char *)iecho + sizeof(struct icmp_echo_hdr);
    for (size_t i = 0; i < data_len; i++) {
        data_ptr[i] = (char)i;
    }
    
    // 计算校验和
    iecho->chksum = inet_chksum(iecho, ping_size);
    
    // 发送ping包
    if (raw_sendto(g_ping_pcb, p, &g_ping_target) != ERR_OK) {
        pbuf_free(p);
        return -1;
    }
    
    pbuf_free(p);
    return 0;
}

// Ping参数定义
#define PING_ID      0x1234
#define PING_SEQNO   0x0001

/**
 * @brief 初始化网络监测（ping功能）
 * @return 0=成功, -1=失败
 */
int network_monitor_init(void)
{
    if (g_netif == NULL) {
        return -1;
    }
    
    // 解析目标IP地址
    if (ip4addr_aton(NETWORK_MONITOR_TARGET_IP, &g_ping_target) == 0) {
        xil_printf("[NET] 错误: 监测目标IP地址格式无效: %s\n\r", NETWORK_MONITOR_TARGET_IP);
        return -1;
    }
    
    // 创建RAW PCB用于ICMP
    g_ping_pcb = raw_new(IP_PROTO_ICMP);
    if (g_ping_pcb == NULL) {
        xil_printf("[NET] 错误: 创建ICMP RAW PCB失败\n\r");
        return -1;
    }
    
    // 设置接收回调
    raw_recv(g_ping_pcb, ping_recv, NULL);
    raw_bind(g_ping_pcb, IP_ADDR_ANY);
    
    // 初始化计数器
    g_ping_counter = 0;
    g_ping_success_count = 0;
    g_ping_fail_count = 0;
    g_network_monitor_counter = 0;
    
    xil_printf("[NET] 网络监测初始化完成，目标: %s\n\r", NETWORK_MONITOR_TARGET_IP);
    return 0;
}

/**
 * @brief 网络监测定时器回调（每10ms调用一次）
 * 应该在platform_zynq.c的timer_callback中调用
 */
void network_monitor_timer_tick(void)
{
    if (g_network_init_status != 1 || g_ping_pcb == NULL) {
        return;
    }
    
    g_network_monitor_counter++;
    
    // 每5秒执行一次ping
    if (g_network_monitor_counter >= NETWORK_MONITOR_INTERVAL) {
        g_network_monitor_counter = 0;
        g_ping_counter++;
        
        // 记录发送前的成功计数
        int success_before = g_ping_success_count;
        
        // 发送ping
        int result = ping_send();
        if (result == 0) {
            // Ping发送成功，等待响应（响应在ping_recv中处理）
            // 注意：由于是异步的，我们无法立即知道是否成功
            // 如果下次ping时成功计数没有增加，说明这次失败了
        } else {
            // Ping发送失败
            g_ping_fail_count++;
            xil_printf("[NET] Ping %s 失败 (发送失败)\n\r", NETWORK_MONITOR_TARGET_IP);
        }
        
        // 检查上次ping是否成功（通过比较成功计数）
        // 注意：这个检查有延迟，因为响应是异步的
        if (g_ping_counter > 1 && g_ping_success_count == success_before) {
            // 上次ping没有收到响应，认为失败
            g_ping_fail_count++;
        }
        
        // 每10次ping报告一次统计
        if (g_ping_counter % 10 == 0 && g_ping_counter > 0) {
            int total_attempts = g_ping_success_count + g_ping_fail_count;
            if (total_attempts > 0) {
                int fail_rate = (g_ping_fail_count * 100) / total_attempts;
                xil_printf("[NET] 网络监测统计: 总计=%d, 成功=%d, 失败=%d, 失败率=%d%%\n\r",
                          total_attempts, g_ping_success_count, g_ping_fail_count, fail_rate);
                
                // 如果失败率超过50%，报告网络不好使
                if (fail_rate > 50) {
                    xil_printf("[NET] ⚠️  警告: 网络连接异常，失败率=%d%%\n\r", fail_rate);
                }
            }
        }
    }
}

#endif // __arm__ || __aarch64__

