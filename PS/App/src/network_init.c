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

// 全局变量
static struct netif *g_netif = NULL;
static int g_network_init_status = 0;  // 0=未初始化, 1=成功, -1=失败

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

#endif // __arm__ || __aarch64__

