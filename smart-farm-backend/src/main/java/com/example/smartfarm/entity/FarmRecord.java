package com.example.smartfarm.entity;

import lombok.Data;
import java.util.Date;

@Data
public class FarmRecord {
    private Integer id;
    private Integer taskId;
    private Integer zoneId;
    private String zoneName;
    private Integer workerId;
    private String workerName;
    private String recordType;
    private String content;
    private String images;
    private String auditStatus;
    private String rejectReason;
    private Date createTime;
}
