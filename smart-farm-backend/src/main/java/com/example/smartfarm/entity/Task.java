package com.example.smartfarm.entity;

import lombok.Data;
import java.util.Date;

@Data
public class Task {
    private Integer id;
    private Integer zoneId;
    private String zoneName;
    private String taskName;
    private String taskType;
    private String description;
    private Integer assigneeId;
    private String assigneeName;
    private Integer creatorId;
    private String rowNo;
    private Date deadline;
    private String status;
    private Date createTime;
}
