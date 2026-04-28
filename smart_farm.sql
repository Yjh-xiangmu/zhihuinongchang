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

 Date: 28/04/2026 11:31:08
*/

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
-- Table structure for ai_chat_history
-- ----------------------------
DROP TABLE IF EXISTS `ai_chat_history`;
CREATE TABLE `ai_chat_history`  (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `role` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `content` text CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL,
  `image_url` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL,
  `create_time` datetime(0) NULL DEFAULT CURRENT_TIMESTAMP(0),
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of ai_chat_history
-- ----------------------------

-- ----------------------------
-- Table structure for farm_anomaly
-- ----------------------------
DROP TABLE IF EXISTS `farm_anomaly`;
CREATE TABLE `farm_anomaly`  (
  `id` int NOT NULL AUTO_INCREMENT,
  `zone_id` int NOT NULL COMMENT '所属区域ID',
  `reporter_id` int NOT NULL COMMENT '上报人ID',
  `anomaly_type` varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '异常类型: PEST, DEVICE, GROWTH, OTHER',
  `description` text CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL COMMENT '问题描述',
  `images` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '现场照片路径，逗号分隔',
  `status` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL DEFAULT 'PENDING' COMMENT '状态: PENDING, PROCESSING, RESOLVED, ESCALATED',
  `handler_id` int NULL DEFAULT NULL COMMENT '处理人ID',
  `handle_note` text CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL COMMENT '处理备注',
  `create_time` datetime(0) NULL DEFAULT CURRENT_TIMESTAMP(0),
  `update_time` datetime(0) NULL DEFAULT CURRENT_TIMESTAMP(0) ON UPDATE CURRENT_TIMESTAMP(0),
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 4 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '异常上报' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of farm_anomaly
-- ----------------------------
INSERT INTO `farm_anomaly` VALUES (1, 2, 6, 'PEST', '发现大量蚜虫，集中在叶背面', NULL, 'RESOLVED', 2, '已处理完毕', '2026-04-27 01:26:36', '2026-04-27 16:19:32');
INSERT INTO `farm_anomaly` VALUES (2, 1, 4, 'DEVICE', '灌溉泵压力不足，出水量只有正常的一半', NULL, 'PROCESSING', 2, '已联系维修人员', '2026-04-27 01:26:36', '2026-04-27 01:26:36');
INSERT INTO `farm_anomaly` VALUES (3, 3, 7, 'GROWTH', '部分黄瓜出现腐烂迹象，约5%受损', NULL, 'RESOLVED', 3, '已摘除病果，喷洒防腐药剂', '2026-04-27 01:26:36', '2026-04-27 01:26:36');
INSERT INTO `farm_anomaly` VALUES (4, 1, 6, 'DEVICE', '测试', NULL, 'PENDING', NULL, NULL, '2026-04-27 01:37:20', '2026-04-27 01:37:20');

-- ----------------------------
-- Table structure for farm_record
-- ----------------------------
DROP TABLE IF EXISTS `farm_record`;
CREATE TABLE `farm_record`  (
  `id` int NOT NULL AUTO_INCREMENT,
  `task_id` int NULL DEFAULT NULL COMMENT '关联任务ID',
  `zone_id` int NOT NULL COMMENT '所属区域ID',
  `worker_id` int NOT NULL COMMENT '提交人ID',
  `record_type` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '记录类型: GROWTH, WATER, FERTILIZER, HARVEST',
  `content` text CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL COMMENT '记录内容（JSON格式）',
  `images` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '图片路径，逗号分隔',
  `audit_status` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT 'PENDING' COMMENT '审核状态: PENDING待审, PASSED通过, REJECTED驳回',
  `reject_reason` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '驳回原因',
  `create_time` datetime(0) NULL DEFAULT CURRENT_TIMESTAMP(0),
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 7 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '农事记录' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of farm_record
-- ----------------------------
INSERT INTO `farm_record` VALUES (1, 2, 1, 5, 'WATER', '{\"remark\":\"浇水已完成，土壤湿润\"}', NULL, 'PASSED', NULL, '2026-04-27 01:26:36');
INSERT INTO `farm_record` VALUES (2, 3, 1, 4, 'FERTILIZER', '{\"amount\":\"20kg\",\"remark\":\"复合肥施用完毕\"}', NULL, 'PENDING', NULL, '2026-04-27 01:26:36');
INSERT INTO `farm_record` VALUES (3, 1, 1, 4, 'GROWTH', '{\"plant_height\":\"45\",\"leaf_color\":\"正常\",\"growth\":\"良\",\"remark\":\"长势良好\"}', NULL, 'PENDING', NULL, '2026-04-27 01:26:36');
INSERT INTO `farm_record` VALUES (4, 4, 2, 6, 'GROWTH', '{\"plant_height\":\"38\",\"leaf_color\":\"偏黄\",\"growth\":\"中\",\"remark\":\"叶片偏黄\"}', NULL, 'REJECTED', '描述不够详细，请补充偏黄的具体位置', '2026-04-27 01:26:36');
INSERT INTO `farm_record` VALUES (5, 5, 3, 7, 'HARVEST', '{\"remark\":\"50kg\"}', NULL, 'PASSED', '', '2026-04-27 18:18:13');
INSERT INTO `farm_record` VALUES (6, 7, 3, 7, 'HARVEST', '{\"yield\":\"100kg\",\"remark\":\"\"}', NULL, 'PASSED', '', '2026-04-27 18:25:44');
INSERT INTO `farm_record` VALUES (7, 8, 3, 7, 'HARVEST', '{\"batchNo\":\"2026-4-27-C02\",\"yield\":\"100kg\",\"gradeA\":\"70kg\",\"gradeB\":\"10kg\",\"gradeC\":\"20kg\",\"remark\":\"\"}', NULL, 'PENDING', NULL, '2026-04-27 18:31:45');

-- ----------------------------
-- Table structure for farm_task
-- ----------------------------
DROP TABLE IF EXISTS `farm_task`;
CREATE TABLE `farm_task`  (
  `id` int NOT NULL AUTO_INCREMENT,
  `zone_id` int NOT NULL COMMENT '所属区域ID',
  `task_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '任务名称',
  `task_type` varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '任务类型: GROWTH, WATER, FERTILIZER, PEST, HARVEST',
  `description` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '任务描述',
  `assignee_id` int NULL DEFAULT NULL COMMENT '执行员工ID',
  `creator_id` int NULL DEFAULT NULL COMMENT '派发人ID',
  `row_no` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '作业排数，如: 第1-3排',
  `deadline` datetime(0) NULL DEFAULT NULL COMMENT '截止时间',
  `status` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT 'PENDING' COMMENT '状态: PENDING待办, DONE已完成, LATE超时',
  `create_time` datetime(0) NULL DEFAULT CURRENT_TIMESTAMP(0),
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 8 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '任务工单' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of farm_task
-- ----------------------------
INSERT INTO `farm_task` VALUES (1, 1, '第1-3排生长巡检', 'GROWTH', '检查株高、叶色，拍照记录', 4, 2, '第1-3排', '2026-04-27 05:26:36', 'DONE', '2026-04-27 01:26:36');
INSERT INTO `farm_task` VALUES (2, 1, '上午浇水', 'WATER', '全排浇透，注意根部', 5, 2, '全排', '2026-04-27 03:26:36', 'DONE', '2026-04-27 01:26:36');
INSERT INTO `farm_task` VALUES (3, 1, '追肥操作', 'FERTILIZER', '复合肥20kg，均匀施用', 4, 2, '第4-6排', '2026-04-27 07:26:36', 'DONE', '2026-04-27 01:26:36');
INSERT INTO `farm_task` VALUES (4, 2, '病虫害巡查', 'PEST', '重点检查叶背面', 6, 2, '全排', '2026-04-27 04:26:36', 'PENDING', '2026-04-27 01:26:36');
INSERT INTO `farm_task` VALUES (5, 3, '今日采收', 'HARVEST', '采收成熟黄瓜，分级装箱', 7, 3, '全排', '2026-04-27 06:26:36', 'DONE', '2026-04-27 01:26:36');
INSERT INTO `farm_task` VALUES (6, 4, '生长记录', 'GROWTH', '记录辣椒开花情况', 6, 3, '全排', '2026-04-27 09:26:36', 'PENDING', '2026-04-27 01:26:36');
INSERT INTO `farm_task` VALUES (7, 3, '今日采收', 'HARVEST', '100kg', 7, 3, '', '2026-04-28 04:00:00', 'DONE', '2026-04-27 18:22:48');
INSERT INTO `farm_task` VALUES (8, 3, '今日采收', 'HARVEST', '100kg', 7, 3, '第5排', '2026-04-28 05:29:00', 'DONE', '2026-04-27 18:29:39');

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
  `area` decimal(10, 2) NULL DEFAULT NULL COMMENT '面积（亩）',
  `target_yield` decimal(10, 2) NULL DEFAULT NULL COMMENT '目标产量（kg）',
  `zone_type` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '区域类型: 大棚, 温室, 露天, 水培',
  `growth_stage` varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '生长阶段: 播种, 缓苗期, 开花期, 结果期, 采收',
  `create_time` datetime(0) NULL DEFAULT CURRENT_TIMESTAMP(0),
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 6 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '种植区域' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of farm_zone
-- ----------------------------
INSERT INTO `farm_zone` VALUES (1, 'A区大棚1号', '西红柿', 2, 'NORMAL', '2026-03-14', 2.50, 3000.00, '大棚', '结果期', '2026-04-27 01:26:35');
INSERT INTO `farm_zone` VALUES (2, 'B区露天2号', '生菜', 2, 'WARNING', '2026-04-09', 1.80, 1500.00, '露天', '缓苗期', '2026-04-27 01:26:35');
INSERT INTO `farm_zone` VALUES (3, 'C区温室3号', '黄瓜', 3, 'HARVESTING', '2026-02-10', 1.20, 2000.00, '温室', '采收', '2026-04-27 01:26:35');
INSERT INTO `farm_zone` VALUES (4, 'D区大棚4号', '辣椒', 3, 'NORMAL', '2026-03-27', 2.00, 1800.00, '大棚', '开花期', '2026-04-27 01:26:35');
INSERT INTO `farm_zone` VALUES (5, 'E区露天5号', '白菜', 2, 'WARNING', '2026-04-15', 3.00, 4000.00, '露天', '播种', '2026-04-27 01:26:35');
INSERT INTO `farm_zone` VALUES (6, 'A区大棚9👌', '草莓', 1, 'NORMAL', '2026-04-27', NULL, NULL, '大棚', '播种', '2026-04-27 01:36:13');

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
) ENGINE = InnoDB AUTO_INCREMENT = 4 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '采收记录' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of harvest_record
-- ----------------------------
INSERT INTO `harvest_record` VALUES (1, 3, 7, '2026-04-C01', 850.00, 600.00, 200.00, 50.00, '黄瓜本批次整体质量良好', '2026-04-27 01:26:36');
INSERT INTO `harvest_record` VALUES (2, 1, 4, '2026-04-A01', 320.00, 250.00, 60.00, 10.00, '西红柿第一批采收', '2026-04-27 01:26:36');
INSERT INTO `harvest_record` VALUES (3, 3, 7, NULL, NULL, NULL, NULL, NULL, NULL, '2026-04-27 18:25:44');
INSERT INTO `harvest_record` VALUES (4, 3, 7, '2026-4-27-C02', NULL, 70.00, 10.00, 20.00, '', '2026-04-27 18:31:45');

-- ----------------------------
-- Table structure for notification
-- ----------------------------
DROP TABLE IF EXISTS `notification`;
CREATE TABLE `notification`  (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL COMMENT '接收人ID',
  `title` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '消息标题',
  `content` text CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL COMMENT '消息内容',
  `type` varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '类型: AUDIT_PASS, AUDIT_REJECT, TASK_TIMEOUT, TASK_NEW, ANOMALY',
  `is_read` tinyint(1) NULL DEFAULT 0 COMMENT '是否已读: 0未读, 1已读',
  `create_time` datetime(0) NULL DEFAULT CURRENT_TIMESTAMP(0),
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 10 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '消息通知' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of notification
-- ----------------------------
INSERT INTO `notification` VALUES (1, 4, '记录审核通过', '您提交的浇水记录已审核通过', 'AUDIT_PASS', 1, '2026-04-27 01:26:36');
INSERT INTO `notification` VALUES (2, 6, '记录被驳回', '您提交的生长记录被驳回，请补充叶黄的具体位置', 'AUDIT_REJECT', 1, '2026-04-27 01:26:36');
INSERT INTO `notification` VALUES (3, 4, '任务超时提醒', '任务【生长巡检】已超过截止时间，请及时完成', 'TASK_TIMEOUT', 1, '2026-04-27 01:26:36');
INSERT INTO `notification` VALUES (4, 7, '异常已处理', '您上报的黄瓜生长异常已由负责人标记为解决', 'ANOMALY', 0, '2026-04-27 01:26:36');
INSERT INTO `notification` VALUES (5, 4, '收到新任务', '您有新任务：追肥操作，请及时处理', 'TASK_NEW', 1, '2026-04-27 01:26:36');
INSERT INTO `notification` VALUES (6, 6, '收到新任务', '您有新任务：病虫害巡查，请及时处理', 'TASK_NEW', 1, '2026-04-27 01:26:36');
INSERT INTO `notification` VALUES (7, 7, '记录审核通过', '您提交的HARVEST记录已审核通过', 'AUDIT_PASS', 0, '2026-04-27 18:18:50');
INSERT INTO `notification` VALUES (8, 7, '收到新任务', '您有新任务：今日采收，请及时处理', 'TASK_NEW', 0, '2026-04-27 18:22:48');
INSERT INTO `notification` VALUES (9, 7, '记录审核通过', '您提交的HARVEST记录已审核通过', 'AUDIT_PASS', 0, '2026-04-27 18:29:09');
INSERT INTO `notification` VALUES (10, 7, '收到新任务', '您有新任务：今日采收，请及时处理', 'TASK_NEW', 0, '2026-04-27 18:29:39');

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
) ENGINE = InnoDB AUTO_INCREMENT = 7 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '系统用户' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of sys_user
-- ----------------------------
INSERT INTO `sys_user` VALUES (1, 'admin', '123456', '王建国', 'ADMIN', '2026-04-27 01:26:35');
INSERT INTO `sys_user` VALUES (2, 'liming', '123456', '李明1', 'MANAGER', '2026-04-27 01:26:35');
INSERT INTO `sys_user` VALUES (3, 'zhangwei', '123456', '张伟', 'MANAGER', '2026-04-27 01:26:35');
INSERT INTO `sys_user` VALUES (4, 'xiaowang', '123456', '小王', 'WORKER', '2026-04-27 01:26:35');
INSERT INTO `sys_user` VALUES (5, 'lihong', '123456', '李红', 'WORKER', '2026-04-27 01:26:35');
INSERT INTO `sys_user` VALUES (6, 'wangfang', '123456', '王芳', 'WORKER', '2026-04-27 01:26:35');
INSERT INTO `sys_user` VALUES (7, 'zhaolei', '123456', '赵磊', 'WORKER', '2026-04-27 01:26:35');

-- ----------------------------
-- Table structure for zone_worker
-- ----------------------------
DROP TABLE IF EXISTS `zone_worker`;
CREATE TABLE `zone_worker`  (
  `id` int NOT NULL AUTO_INCREMENT,
  `zone_id` int NOT NULL COMMENT '区域ID',
  `worker_id` int NOT NULL COMMENT '员工ID',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `uk_zone_worker`(`zone_id`, `worker_id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 9 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '区域员工关联' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of zone_worker
-- ----------------------------
INSERT INTO `zone_worker` VALUES (1, 1, 4);
INSERT INTO `zone_worker` VALUES (2, 1, 5);
INSERT INTO `zone_worker` VALUES (3, 2, 6);
INSERT INTO `zone_worker` VALUES (4, 3, 7);
INSERT INTO `zone_worker` VALUES (5, 4, 6);
INSERT INTO `zone_worker` VALUES (6, 4, 7);
INSERT INTO `zone_worker` VALUES (7, 5, 4);
INSERT INTO `zone_worker` VALUES (8, 5, 5);
INSERT INTO `zone_worker` VALUES (9, 6, 4);
INSERT INTO `zone_worker` VALUES (10, 6, 5);
INSERT INTO `zone_worker` VALUES (11, 6, 6);
INSERT INTO `zone_worker` VALUES (12, 6, 7);

SET FOREIGN_KEY_CHECKS = 1;
