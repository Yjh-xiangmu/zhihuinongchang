package com.example.smartfarm.controller;

import com.example.smartfarm.common.Result;
import com.example.smartfarm.entity.Anomaly;
import com.example.smartfarm.mapper.AnomalyMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/anomalies")
@CrossOrigin
public class AnomalyController {

    @Autowired
    private AnomalyMapper anomalyMapper;

    // 管理员查看全部异常
    @GetMapping("/list/all")
    public Result listAll() {
        return Result.success(anomalyMapper.listAll());
    }

    // 负责人查看所辖区域的异常
    @GetMapping("/list/zone/{zoneId}")
    public Result listByZone(@PathVariable Integer zoneId) {
        return Result.success(anomalyMapper.listByZoneId(zoneId));
    }

    // 员工查看自己上报的异常
    @GetMapping("/list/reporter/{reporterId}")
    public Result listByReporter(@PathVariable Integer reporterId) {
        return Result.success(anomalyMapper.listByReporterId(reporterId));
    }

    // 员工上报新异常
    @PostMapping("/add")
    public Result add(@RequestBody Anomaly anomaly) {
        anomaly.setStatus("PENDING");
        anomalyMapper.insert(anomaly);
        return Result.success(anomaly);
    }

    // 负责人处理异常（更新状态/备注）
    @PutMapping("/handle")
    public Result handle(@RequestBody Anomaly anomaly) {
        anomalyMapper.update(anomaly);
        return Result.success();
    }
}
