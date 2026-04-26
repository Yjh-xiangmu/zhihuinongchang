package com.example.smartfarm.entity;

import lombok.Data;
import java.math.BigDecimal;
import java.util.Date;

@Data
public class HarvestRecord {
    private Integer id;
    private Integer zoneId;
    private String zoneName;
    private Integer workerId;
    private String workerName;
    private String batchNo;
    private BigDecimal actualWeight;
    private BigDecimal gradeA;
    private BigDecimal gradeB;
    private BigDecimal gradeC;
    private String remark;
    private Date createTime;
}
