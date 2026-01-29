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
 * @brief 配置YT8531 PHY为千兆模式
 * @param emacps_instance EMACPS实例指针
 * @return 0=成功, -1=失败
 */
static int configure_yt8531_gigabit_mode(XEmacPs *emacps_instance)
{
    u16 phy_reg;
    u16 phy_addr = 0;  // 通常PHY地址为0或1，根据硬件设计
    int retry_count = 0;
    int max_retries = 3;
    int status = 0;

    xil_printf("[NET] 开始配置YT8531 PHY为千兆模式...\n\r");

    // 尝试读取PHY ID以确认PHY存在
    for (phy_addr = 0; phy_addr < 32; phy_addr++) {
        status = XEmacPs_PhyRead(emacps_instance, phy_addr, YT8531_PHY_ID1_REG, &phy_reg);
        if (status == XST_SUCCESS) {
            xil_printf("[NET] 检测到PHY，地址: 0x%02X, ID1: 0x%04X\n\r", phy_addr, phy_reg);
            break;
        }
    }

    if (phy_addr >= 32) {
        xil_printf("[NET] 错误: 未找到YT8531 PHY芯片\n\r");
        return -1;
    }

    // 读取PHY ID2
    status = XEmacPs_PhyRead(emacps_instance, phy_addr, YT8531_PHY_ID2_REG, &phy_reg);
    if (status == XST_SUCCESS) {
        xil_printf("[NET] PHY ID2: 0x%04X\n\r", phy_reg);
    }

    // 软件复位PHY
    xil_printf("[NET] 复位PHY...\n\r");
    status = XEmacPs_PhyRead(emacps_instance, phy_addr, YT8531_BMCR_REG, &phy_reg);
    if (status != XST_SUCCESS) {
        xil_printf("[NET] 错误: 读取BMCR寄存器失败\n\r");
        return -1;
    }

    phy_reg |= BMCR_RESET;
    status = XEmacPs_PhyWrite(emacps_instance, phy_addr, YT8531_BMCR_REG, phy_reg);
    if (status != XST_SUCCESS) {
        xil_printf("[NET] 错误: 写入BMCR寄存器失败\n\r");
        return -1;
    }

    // 等待复位完成 (至少10ms)
    usleep(10000);

    // 配置为千兆模式
    xil_printf("[NET] 配置千兆模式...\n\r");
    
    // 读取当前BMCR值
    status = XEmacPs_PhyRead(emacps_instance, phy_addr, YT8531_BMCR_REG, &phy_reg);
    if (status != XST_SUCCESS) {
        xil_printf("[NET] 错误: 读取BMCR寄存器失败\n\r");
        return -1;
    }

    // 配置基本模式控制寄存器：使能自动协商，千兆模式
    phy_reg = BMCR_AN_ENABLE | BMCR_SPEED_1000;
    status = XEmacPs_PhyWrite(emacps_instance, phy_addr, YT8531_BMCR_REG, phy_reg);
    if (status != XST_SUCCESS) {
        xil_printf("[NET] 错误: 写入BMCR寄存器失败\n\r");
        return -1;
    }

    // 配置自动协商通告寄存器：支持10M/100M/1000M全双工
    phy_reg = ANAR_SELECTOR | ANAR_10HALF | ANAR_10FULL | 
              ANAR_100HALF | ANAR_100FULL | ANAR_PAUSE;
    status = XEmacPs_PhyWrite(emacps_instance, phy_addr, YT8531_ANAR_REG, phy_reg);
    if (status != XST_SUCCESS) {
        xil_printf("[NET] 错误: 写入ANAR寄存器失败\n\r");
        return -1;
    }

    // 配置千兆控制寄存器：支持1000M全双工和半双工
    phy_reg = GBECTRL_1000HALF | GBECTRL_1000FULL;
    status = XEmacPs_PhyWrite(emacps_instance, phy_addr, YT8531_GBECTRL_REG, phy_reg);
    if (status != XST_SUCCESS) {
        xil_printf("[NET] 警告: 写入GBECTRL寄存器失败，可能不支持此寄存器\n\r");
        // 某些PHY可能没有此寄存器，继续执行
    }

    // 重新启动自动协商
    xil_printf("[NET] 启动自动协商...\n\r");
    status = XEmacPs_PhyRead(emacps_instance, phy_addr, YT8531_BMCR_REG, &phy_reg);
    if (status != XST_SUCCESS) {
        xil_printf("[NET] 错误: 读取BMCR寄存器失败\n\r");
        return -1;
    }

    phy_reg |= BMCR_AN_ENABLE;
    status = XEmacPs_PhyWrite(emacps_instance, phy_addr, YT8531_BMCR_REG, phy_reg);
    if (status != XST_SUCCESS) {
        xil_printf("[NET] 错误: 写入BMCR寄存器失败\n\r");
        return -1;
    }

    // 等待自动协商完成 (最多等待5秒)
    xil_printf("[NET] 等待自动协商完成...\n\r");
    for (retry_count = 0; retry_count < 50; retry_count++) {
        usleep(100000);  // 等待100ms

        status = XEmacPs_PhyRead(emacps_instance, phy_addr, YT8531_BMSR_REG, &phy_reg);
        if (status == XST_SUCCESS) {
            if (phy_reg & 0x0020) {  // 自动协商完成位
                xil_printf("[NET] 自动协商完成\n\r");
                break;
            }
        }
    }

    if (retry_count >= 50) {
        xil_printf("[NET] 警告: 自动协商超时\n\r");
    }

    // 读取协商结果
    status = XEmacPs_PhyRead(emacps_instance, phy_addr, YT8531_ANLPAR_REG, &phy_reg);
    if (status == XST_SUCCESS) {
        xil_printf("[NET] 链路伙伴能力: 0x%04X\n\r", phy_reg);
    }

    // 读取PHY状态寄存器
    status = XEmacPs_PhyRead(emacps_instance, phy_addr, YT8531_PHYSR_REG, &phy_reg);
    if (status == XST_SUCCESS) {
        xil_printf("[NET] PHY状态寄存器: 0x%04X\n\r", phy_reg);
        if (phy_reg & 0x0004) {
            xil_printf("[NET] 链路已建立\n\r");
        } else {
            xil_printf("[NET] 警告: 链路未建立\n\r");
        }
    }

    xil_printf("[NET] YT8531 PHY配置完成\n\r");
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

    // 配置YT8531 PHY为千兆模式
    // 获取EMACPS实例
    emacps_instance = (XEmacPs *)netif->state;
    if (emacps_instance != NULL) {
        xil_printf("[NET] 配置YT8531 PHY芯片...\n\r");
        status = configure_yt8531_gigabit_mode(emacps_instance);
        if (status != 0) {
            xil_printf("[NET] 警告: YT8531 PHY配置失败，但继续网络初始化\n\r");
        }
    } else {
        xil_printf("[NET] 警告: 无法获取EMACPS实例，跳过PHY配置\n\r");
    }

    // 等待一段时间让网络稳定
    xil_printf("[NET] 等待网络稳定...\n\r");
    usleep(500000);  // 等待500ms

    // 检查链路状态
    if (netif_is_link_up(netif)) {
        xil_printf("[NET] 网络链路已建立\n\r");
    } else {
        xil_printf("[NET] 警告: 网络链路未建立，请检查网线连接\n\r");
    }

    // 打印网络配置信息
    xil_printf("[NET] 网络配置信息:\n\r");
    xil_printf("[NET]   IP地址: %s\n\r", ip4addr_ntoa(&netif->ip_addr));
    xil_printf("[NET]   子网掩码: %s\n\r", ip4addr_ntoa(&netif->netmask));
    xil_printf("[NET]   网关: %s\n\r", ip4addr_ntoa(&netif->gw));
    xil_printf("[NET]   MAC地址: %02X:%02X:%02X:%02X:%02X:%02X\n\r",
               netif->hwaddr[0], netif->hwaddr[1], netif->hwaddr[2],
               netif->hwaddr[3], netif->hwaddr[4], netif->hwaddr[5]);

    g_network_init_status = 1;
    xil_printf("========================================\n\r");
    xil_printf("[NET] 网络初始化完成 (成功)\n\r");
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

