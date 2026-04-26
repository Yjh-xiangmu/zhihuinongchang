/*
  smart_farm_add.sql
  在已有 smart_farm 库（sys_user / farm_zone / farm_task / farm_record）的基础上，
  追加以下三张表及测试数据，复制到 Navicat 等工具执行即可。
*/

USE `smart_farm`;
SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
-- 1. 给 farm_zone 追加缺失字段（如果已存在会跳过）
-- ----------------------------
ALTER TABLE `farm_zone`
    ADD COLUMN IF NOT EXISTS `area`         DECIMAL(10,2) DEFAULT NULL   COMMENT '种植面积(亩)',
    ADD COLUMN IF NOT EXISTS `target_yield` DECIMAL(10,2) DEFAULT NULL   COMMENT '预期目标产量(kg)',
    ADD COLUMN IF NOT EXISTS `zone_type`    VARCHAR(20)   DEFAULT 'GREENHOUSE' COMMENT '区域类型: GREENHOUSE大棚, OUTDOOR露天, WAREHOUSE温室',
    ADD COLUMN IF NOT EXISTS `growth_stage` VARCHAR(30)   DEFAULT 'SEEDING' COMMENT '生长阶段: SEEDING播种,SEEDLING缓苗期,FLOWERING开花期,FRUITING结果期,HARVESTING采收';

-- ----------------------------
-- 2. 给 farm_task 追加缺失字段
-- ----------------------------
ALTER TABLE `farm_task`
    ADD COLUMN IF NOT EXISTS `task_type`    VARCHAR(30) DEFAULT NULL COMMENT '任务类型: WATER浇水, FERTILIZE施肥, INSPECT巡查, HARVEST采收, OTHER其他',
    ADD COLUMN IF NOT EXISTS `description`  TEXT        DEFAULT NULL COMMENT '任务详情',
    ADD COLUMN IF NOT EXISTS `creator_id`   INT         DEFAULT NULL COMMENT '创建人ID（区域负责人）',
    ADD COLUMN IF NOT EXISTS `row_no`       VARCHAR(50) DEFAULT NULL COMMENT '作业排数，如: A排1-5行';

-- ----------------------------
-- 3. 异常上报表
-- ----------------------------
DROP TABLE IF EXISTS `farm_anomaly`;
CREATE TABLE `farm_anomaly` (
    `id`           INT          NOT NULL AUTO_INCREMENT,
    `zone_id`      INT          NOT NULL COMMENT '所属区域ID',
    `reporter_id`  INT          NOT NULL COMMENT '上报人ID',
    `anomaly_type` VARCHAR(30)  NOT NULL COMMENT '异常类型: PEST病虫害, DEVICE设备损坏, GROWTH生长异常, OTHER其他',
    `description`  TEXT             NULL COMMENT '问题描述',
    `images`       VARCHAR(500)     NULL COMMENT '现场照片路径，逗号分隔',
    `status`       VARCHAR(20)  NOT NULL DEFAULT 'PENDING' COMMENT '状态: PENDING待处理, PROCESSING处理中, RESOLVED已解决, ESCALATED已上报管理员',
    `handler_id`   INT              NULL COMMENT '处理人ID',
    `handle_note`  TEXT             NULL COMMENT '处理备注',
    `create_time`  DATETIME(0)      NULL DEFAULT CURRENT_TIMESTAMP(0),
    `update_time`  DATETIME(0)      NULL DEFAULT CURRENT_TIMESTAMP(0) ON UPDATE CURRENT_TIMESTAMP(0),
    PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- 4. 采收记录表
-- ----------------------------
DROP TABLE IF EXISTS `harvest_record`;
CREATE TABLE `harvest_record` (
    `id`            INT          NOT NULL AUTO_INCREMENT,
    `zone_id`       INT          NOT NULL COMMENT '所属区域ID',
    `worker_id`     INT          NOT NULL COMMENT '采收人ID',
    `batch_no`      VARCHAR(50)      NULL COMMENT '批次号，如: 2026-04-A01',
    `actual_weight` DECIMAL(10,2)    NULL COMMENT '实际采收重量(kg)',
    `grade_a`       DECIMAL(10,2)    NULL DEFAULT 0 COMMENT 'A级产量(kg)',
    `grade_b`       DECIMAL(10,2)    NULL DEFAULT 0 COMMENT 'B级产量(kg)',
    `grade_c`       DECIMAL(10,2)    NULL DEFAULT 0 COMMENT 'C级产量(kg)',
    `remark`        VARCHAR(500)     NULL COMMENT '备注',
    `create_time`   DATETIME(0)      NULL DEFAULT CURRENT_TIMESTAMP(0),
    PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- 5. 通知消息表
-- ----------------------------
DROP TABLE IF EXISTS `notification`;
CREATE TABLE `notification` (
    `id`          INT          NOT NULL AUTO_INCREMENT,
    `user_id`     INT          NOT NULL COMMENT '接收人ID',
    `title`       VARCHAR(100) NOT NULL COMMENT '消息标题',
    `content`     TEXT             NULL COMMENT '消息内容',
    `type`        VARCHAR(30)      NULL COMMENT '类型: AUDIT_PASS, AUDIT_REJECT, TASK_TIMEOUT, ANOMALY',
    `is_read`     TINYINT(1)       NULL DEFAULT 0 COMMENT '是否已读: 0未读, 1已读',
    `create_time` DATETIME(0)      NULL DEFAULT CURRENT_TIMESTAMP(0),
    PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- 6. 测试数据
-- ----------------------------

-- 补充更多用户
INSERT INTO `sys_user` (`username`, `password`, `real_name`, `role`) VALUES
('zhangwei',   '123456', '张伟',   'MANAGER'),
('lihong',     '123456', '李红',   'WORKER'),
('wangfang',   '123456', '王芳',   'WORKER'),
('zhaolei',    '123456', '赵磊',   'WORKER');

-- 种植区域（manager_id 对应 sys_user 的 id）
INSERT INTO `farm_zone` (`zone_name`, `crop_name`, `manager_id`, `status`, `plant_date`, `area`, `target_yield`, `zone_type`, `growth_stage`) VALUES
('A区大棚1号', '西红柿',  2, 'NORMAL',     '2026-03-01', 2.5, 5000, 'GREENHOUSE', 'FRUITING'),
('A区大棚2号', '黄瓜',    2, 'WARNING',    '2026-03-10', 1.8, 3500, 'GREENHOUSE', 'FLOWERING'),
('B区露天1号', '白菜',    5, 'HARVESTING', '2026-02-15', 3.0, 8000, 'OUTDOOR',   'HARVESTING'),
('B区温室1号', '草莓',    5, 'NORMAL',     '2026-03-20', 1.2, 2000, 'WAREHOUSE', 'FRUITING');

-- 任务（zone_id基于上面插入顺序，assignee_id为worker）
INSERT INTO `farm_task` (`zone_id`, `task_name`, `task_type`, `description`, `assignee_id`, `creator_id`, `row_no`, `deadline`, `status`) VALUES
(1, '西红柿浇水', 'WATER',     '今日上午完成浇水，每行浇透', 3, 2, 'A排1-5行', DATE_ADD(NOW(), INTERVAL 2 HOUR),  'PENDING'),
(1, '施基础肥',   'FERTILIZE', '按照配比施复合肥，注意剂量', 3, 2, 'A排1-10行',DATE_ADD(NOW(), INTERVAL 4 HOUR),  'PENDING'),
(1, '病虫害巡查', 'INSPECT',   '重点检查叶片背面',          6, 2, '全区',      DATE_ADD(NOW(), INTERVAL 6 HOUR),  'PENDING'),
(2, '黄瓜授粉',   'OTHER',     '人工辅助授粉',              6, 2, 'B排全部',   DATE_ADD(NOW(), INTERVAL 1 HOUR),  'PENDING'),
(3, '白菜采收',   'HARVEST',   '标准成熟度采收，分级装箱',  7, 5, '全区',      DATE_ADD(NOW(), INTERVAL 8 HOUR),  'DONE'),
(1, '昨日浇水',   'WATER',     '补充昨日未完成浇水',        3, 2, 'C排1-3行',  DATE_ADD(NOW(), INTERVAL -2 HOUR), 'LATE');

-- 农事记录（farm_record）
INSERT INTO `farm_record` (`task_id`, `zone_id`, `worker_id`, `record_type`, `content`, `audit_status`) VALUES
(1, 1, 3, 'WATER',      '{"remark":"浇水已完成，土壤湿润"}',                             'PENDING'),
(2, 1, 3, 'FERTILIZER', '{"remark":"复合肥施用完毕","amount":"20kg"}',                    'PENDING'),
(3, 1, 6, 'GROWTH',     '{"plant_height":"45cm","leaf_color":"正常","growth":"良","remark":"长势良好"}', 'PASSED'),
(4, 2, 6, 'GROWTH',     '{"plant_height":"38cm","leaf_color":"偏黄","growth":"中","remark":"叶片偏黄，注意营养"}', 'REJECTED');

-- 异常上报
INSERT INTO `farm_anomaly` (`zone_id`, `reporter_id`, `anomaly_type`, `description`, `status`) VALUES
(2, 6, 'PEST',   '发现大量蚜虫，集中在B区2号大棚黄瓜叶背面', 'PENDING'),
(1, 3, 'DEVICE', '灌溉泵压力不足，出水量只有正常的一半',      'PROCESSING'),
(3, 7, 'GROWTH', '部分白菜出现腐烂迹象，约5%受损',            'RESOLVED');

-- 采收记录
INSERT INTO `harvest_record` (`zone_id`, `worker_id`, `batch_no`, `actual_weight`, `grade_a`, `grade_b`, `grade_c`, `remark`) VALUES
(3, 7, '2026-04-B01', 850.0, 600.0, 200.0, 50.0, '白菜本批次整体质量良好'),
(1, 3, '2026-04-A01', 320.0, 250.0,  60.0, 10.0, '西红柿第一批采收');

-- 通知消息（给小王 id=3、李红 id=6）
INSERT INTO `notification` (`user_id`, `title`, `content`, `type`) VALUES
(3, '记录审核通过', '您提交的西红柿生长记录已审核通过', 'AUDIT_PASS'),
(6, '记录被驳回',   '您提交的黄瓜生长记录被驳回，请补充叶黄原因', 'AUDIT_REJECT'),
(3, '任务超时提醒', '任务【昨日浇水】已超过截止时间，请及时完成', 'TASK_TIMEOUT'),
(7, '异常已处理',   '您上报的白菜生长异常已由负责人标记为解决', 'ANOMALY');

SET FOREIGN_KEY_CHECKS = 1;
