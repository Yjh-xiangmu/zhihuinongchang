package com.example.smartfarm.controller;

import com.example.smartfarm.common.Result;
import com.example.smartfarm.entity.HarvestRecord;
import com.example.smartfarm.mapper.HarvestRecordMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/harvests")
@CrossOrigin
public class HarvestController {

    @Autowired
    private HarvestRecordMapper harvestRecordMapper;

    @GetMapping("/list/all")
    public Result listAll() {
        return Result.success(harvestRecordMapper.listAll());
    }

    @GetMapping("/list/zone/{zoneId}")
    public Result listByZone(@PathVariable Integer zoneId) {
        return Result.success(harvestRecordMapper.listByZoneId(zoneId));
    }

    @GetMapping("/list/worker/{workerId}")
    public Result listByWorker(@PathVariable Integer workerId) {
        return Result.success(harvestRecordMapper.listByWorkerId(workerId));
    }

    @PostMapping("/add")
    public Result add(@RequestBody HarvestRecord record) {
        harvestRecordMapper.insert(record);
        return Result.success(record);
    }
}
