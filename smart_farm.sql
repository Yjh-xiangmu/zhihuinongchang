/*
 Navicat Premium Data Transfer

 Source Server         : yjh
 Source Server Type    : MySQL
 Source Server Version : 80026
 Source Host           : localhost:3306
 Source Schema         : smart_farm

 Target Server Type    : MySQL
 Target Server Version : 80026
 File Encoding         : 65001

 Date: 27/04/2026 00:56:10
*/

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
-- Table structure for farm_anomaly
-- ----------------------------
DROP TABLE IF EXISTS `farm_anomaly`;
CREATE TABLE `farm_anomaly`  (
  `id` int NOT NULL AUTO_INCREMENT,
  `zone_id` int NOT NULL COMMENT '所属区域ID',
  `reporter_id` int NOT NULL COMMENT '上报人ID',
  `anomaly_type` varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '异常类型: PEST病虫害, DEVICE设备损坏, GROWTH生长异常, OTHER其他',
  `description` text CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL COMMENT '问题描述',
  `images` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '现场照片路径，逗号分隔',
  `status` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL DEFAULT 'PENDING' COMMENT '状态: PENDING待处理, PROCESSING处理中, RESOLVED已解决, ESCALATED已上报管理员',
  `handler_id` int NULL DEFAULT NULL COMMENT '处理人ID',
  `handle_note` text CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL COMMENT '处理备注',
  `create_time` datetime(0) NULL DEFAULT CURRENT_TIMESTAMP(0),
  `update_time` datetime(0) NULL DEFAULT CURRENT_TIMESTAMP(0) ON UPDATE CURRENT_TIMESTAMP(0),
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 4 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of farm_anomaly
-- ----------------------------
INSERT INTO `farm_anomaly` VALUES (1, 2, 6, 'PEST', '发现大量蚜虫，集中在B区2号大棚黄瓜叶背面', NULL, 'PENDING', NULL, NULL, '2026-04-27 00:55:24', '2026-04-27 00:55:24');
INSERT INTO `farm_anomaly` VALUES (2, 1, 3, 'DEVICE', '灌溉泵压力不足，出水量只有正常的一半', NULL, 'PROCESSING', NULL, NULL, '2026-04-27 00:55:24', '2026-04-27 00:55:24');
INSERT INTO `farm_anomaly` VALUES (3, 3, 7, 'GROWTH', '部分白菜出现腐烂迹象，约5%受损', NULL, 'RESOLVED', NULL, NULL, '2026-04-27 00:55:24', '2026-04-27 00:55:24');

-- ----------------------------
-- Table structure for farm_record
-- ----------------------------
DROP TABLE IF EXISTS `farm_record`;
CREATE TABLE `farm_record`  (
  `id` int NOT NULL AUTO_INCREMENT,
  `task_id` int NULL DEFAULT NULL COMMENT '关联任务ID',
  `zone_id` int NOT NULL COMMENT '所属区域ID',
  `worker_id` int NOT NULL COMMENT '提交人ID',
  `record_type` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '记录类型: GROWTH生长, WATER浇水, FERTILIZER施肥',
  `content` text CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL COMMENT '文字描述或JSON数据(株高/叶色等)',
  `images` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '图片路径，逗号分隔',
  `audit_status` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT 'PENDING' COMMENT '审核状态: PENDING待审, PASSED通过, REJECTED驳回',
  `create_time` datetime(0) NULL DEFAULT CURRENT_TIMESTAMP(0),
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of farm_record
-- ----------------------------
INSERT INTO `farm_record` VALUES (1, 1, 1, 3, 'WATER', '{\"remark\":\"浇水已完成，土壤湿润\"}', NULL, 'PENDING', '2026-04-27 00:55:24');
INSERT INTO `farm_record` VALUES (2, 2, 1, 3, 'FERTILIZER', '{\"remark\":\"复合肥施用完毕\",\"amount\":\"20kg\"}', NULL, 'PENDING', '2026-04-27 00:55:24');
INSERT INTO `farm_record` VALUES (3, 3, 1, 6, 'GROWTH', '{\"plant_height\":\"45cm\",\"leaf_color\":\"正常\",\"growth\":\"良\",\"remark\":\"长势良好\"}', NULL, 'PASSED', '2026-04-27 00:55:24');
INSERT INTO `farm_record` VALUES (4, 4, 2, 6, 'GROWTH', '{\"plant_height\":\"38cm\",\"leaf_color\":\"偏黄\",\"growth\":\"中\",\"remark\":\"叶片偏黄，注意营养\"}', NULL, 'REJECTED', '2026-04-27 00:55:24');

-- ----------------------------
-- Table structure for farm_task
-- ----------------------------
DROP TABLE IF EXISTS `farm_task`;
CREATE TABLE `farm_task`  (
  `id` int NOT NULL AUTO_INCREMENT,
  `zone_id` int NOT NULL COMMENT '所属区域ID',
  `task_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '任务名称',
  `assignee_id` int NULL DEFAULT NULL COMMENT '执行员工ID',
  `deadline` datetime(0) NULL DEFAULT NULL COMMENT '截止时间',
  `status` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT 'PENDING' COMMENT '状态: PENDING待办, DONE已完成, LATE超时',
  `create_time` datetime(0) NULL DEFAULT CURRENT_TIMESTAMP(0),
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of farm_task
-- ----------------------------

-- ----------------------------
-- Table structure for farm_zone
-- ----------------------------
DROP TABLE IF EXISTS `farm_zone`;
CREATE TABLE `farm_zone`  (
  `id` int NOT NULL AUTO_INCREMENT,
  `zone_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '区域名称，如: A区大棚1号',
  `crop_name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '种植作物，如: 西红柿',
  `manager_id` int NULL DEFAULT NULL COMMENT '区域负责人ID',
  `status` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT 'NORMAL' COMMENT '状态: NORMAL, WARNING, HARVESTING',
  `plant_date` date NULL DEFAULT NULL COMMENT '播种日期',
  `create_time` datetime(0) NULL DEFAULT CURRENT_TIMESTAMP(0),
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of farm_zone
-- ----------------------------

-- ----------------------------
-- Table structure for harvest_record
-- ----------------------------
DROP TABLE IF EXISTS `harvest_record`;
CREATE TABLE `harvest_record`  (
  `id` int NOT NULL AUTO_INCREMENT,
  `zone_id` int NOT NULL COMMENT '所属区域ID',
  `worker_id` int NOT NULL COMMENT '采收人ID',
  `batch_no` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '批次号，如: 2026-04-A01',
  `actual_weight` decimal(10, 2) NULL DEFAULT NULL COMMENT '实际采收重量(kg)',
  `grade_a` decimal(10, 2) NULL DEFAULT 0.00 COMMENT 'A级产量(kg)',
  `grade_b` decimal(10, 2) NULL DEFAULT 0.00 COMMENT 'B级产量(kg)',
  `grade_c` decimal(10, 2) NULL DEFAULT 0.00 COMMENT 'C级产量(kg)',
  `remark` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '备注',
  `create_time` datetime(0) NULL DEFAULT CURRENT_TIMESTAMP(0),
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 3 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of harvest_record
-- ----------------------------
INSERT INTO `harvest_record` VALUES (1, 3, 7, '2026-04-B01', 850.00, 600.00, 200.00, 50.00, '白菜本批次整体质量良好', '2026-04-27 00:55:25');
INSERT INTO `harvest_record` VALUES (2, 1, 3, '2026-04-A01', 320.00, 250.00, 60.00, 10.00, '西红柿第一批采收', '2026-04-27 00:55:25');

-- ----------------------------
-- Table structure for notification
-- ----------------------------
DROP TABLE IF EXISTS `notification`;
CREATE TABLE `notification`  (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL COMMENT '接收人ID',
  `title` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '消息标题',
  `content` text CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL COMMENT '消息内容',
  `type` varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '类型: AUDIT_PASS, AUDIT_REJECT, TASK_TIMEOUT, ANOMALY',
  `is_read` tinyint(1) NULL DEFAULT 0 COMMENT '是否已读: 0未读, 1已读',
  `create_time` datetime(0) NULL DEFAULT CURRENT_TIMESTAMP(0),
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 5 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of notification
-- ----------------------------
INSERT INTO `notification` VALUES (1, 3, '记录审核通过', '您提交的西红柿生长记录已审核通过', 'AUDIT_PASS', 0, '2026-04-27 00:55:25');
INSERT INTO `notification` VALUES (2, 6, '记录被驳回', '您提交的黄瓜生长记录被驳回，请补充叶黄原因', 'AUDIT_REJECT', 0, '2026-04-27 00:55:25');
INSERT INTO `notification` VALUES (3, 3, '任务超时提醒', '任务【昨日浇水】已超过截止时间，请及时完成', 'TASK_TIMEOUT', 0, '2026-04-27 00:55:25');
INSERT INTO `notification` VALUES (4, 7, '异常已处理', '您上报的白菜生长异常已由负责人标记为解决', 'ANOMALY', 0, '2026-04-27 00:55:25');

-- ----------------------------
-- Table structure for sys_user
-- ----------------------------
DROP TABLE IF EXISTS `sys_user`;
CREATE TABLE `sys_user`  (
  `id` int NOT NULL AUTO_INCREMENT,
  `username` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '登录账号',
  `password` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL DEFAULT '123456' COMMENT '登录密码',
  `real_name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '真实姓名',
  `role` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '角色: ADMIN, MANAGER, WORKER',
  `create_time` datetime(0) NULL DEFAULT CURRENT_TIMESTAMP(0),
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 4 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of sys_user
-- ----------------------------
INSERT INTO `sys_user` VALUES (1, 'admin', '123456', '王建国', 'ADMIN', '2026-04-26 22:51:16');
INSERT INTO `sys_user` VALUES (2, 'liming', '123456', '李明', 'MANAGER', '2026-04-26 22:51:16');
INSERT INTO `sys_user` VALUES (3, 'xiaowang', '123456', '小王', 'WORKER', '2026-04-26 22:51:16');
INSERT INTO `sys_user` VALUES (4, 'zhangwei', '123456', '张伟', 'MANAGER', '2026-04-27 00:55:24');
INSERT INTO `sys_user` VALUES (5, 'lihong', '123456', '李红', 'WORKER', '2026-04-27 00:55:24');
INSERT INTO `sys_user` VALUES (6, 'wangfang', '123456', '王芳', 'WORKER', '2026-04-27 00:55:24');
INSERT INTO `sys_user` VALUES (7, 'zhaolei', '123456', '赵磊', 'WORKER', '2026-04-27 00:55:24');

SET FOREIGN_KEY_CHECKS = 1;
