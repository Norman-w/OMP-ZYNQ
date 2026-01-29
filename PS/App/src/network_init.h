/**
 *****************************************************************************
 * 网络初始化模块头文件
 *****************************************************************************
 *
 * @File   : network_init.h
 * @By     : Norman
 * @Version: V1.0
 * @Date   : 2024
 * @Forum  : OMP BY NORMAN (WIP) Basedon Xiaomeige
 *****************************************************************************
**/

#ifndef NETWORK_INIT_H_
#define NETWORK_INIT_H_

#ifdef __cplusplus
extern "C" {
#endif

#if defined (__arm__) || defined (__aarch64__)
#include "lwip/netif.h"

/**
 * @brief 初始化网络接口并设置固定IP
 * @return 0=成功, -1=失败
 * @note 失败不会影响示波器正常功能
 */
int network_init(void);

/**
 * @brief 获取网络初始化状态
 * @return 1=成功, -1=失败, 0=未初始化
 */
int network_get_init_status(void);

/**
 * @brief 获取网络接口指针
 * @return 网络接口指针，失败返回NULL
 */
struct netif* network_get_netif(void);

#endif // __arm__ || __aarch64__

#ifdef __cplusplus
}
#endif

#endif /* NETWORK_INIT_H_ */

