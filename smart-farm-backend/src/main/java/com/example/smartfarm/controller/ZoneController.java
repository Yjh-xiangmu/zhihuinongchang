package com.example.smartfarm.controller;

import com.example.smartfarm.common.Result;
import com.example.smartfarm.entity.User;
import com.example.smartfarm.entity.Zone;
import com.example.smartfarm.mapper.ZoneMapper;
import com.example.smartfarm.mapper.ZoneWorkerMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/zones")
@CrossOrigin
public class ZoneController {

    @Autowired
    private ZoneMapper zoneMapper;

    @Autowired
    private ZoneWorkerMapper zoneWorkerMapper;

    // 获取全部区域
    @GetMapping("/list")
    public Result listAll() {
        return Result.success(zoneMapper.listAll());
    }

    // 获取某负责人的区域
    @GetMapping("/list/manager/{managerId}")
    public Result listByManager(@PathVariable Integer managerId) {
        return Result.success(zoneMapper.listByManagerId(managerId));
    }

    // 新建区域
    @PostMapping("/add")
    public Result add(@RequestBody Zone zone) {
        zoneMapper.insert(zone);
        return Result.success(zone);
    }

    // 更新区域
    @PutMapping("/update")
    public Result update(@RequestBody Zone zone) {
        zoneMapper.update(zone);
        return Result.success();
    }

    // 删除区域
    @DeleteMapping("/delete/{id}")
    public Result delete(@PathVariable Integer id) {
        zoneMapper.deleteById(id);
        zoneWorkerMapper.deleteByZone(id); // 同步删关联
        return Result.success();
    }

    // 查询某区域的员工列表
    @GetMapping("/{zoneId}/workers")
    public Result getWorkers(@PathVariable Integer zoneId) {
        return Result.success(zoneWorkerMapper.listWorkersByZone(zoneId));
    }

    // 设置某区域的员工（传 workerIds 列表，全量替换）
    @PostMapping("/{zoneId}/workers")
    public Result setWorkers(@PathVariable Integer zoneId, @RequestBody Map<String, List<Integer>> body) {
        List<Integer> workerIds = body.get("workerIds");
        zoneWorkerMapper.deleteByZone(zoneId); // 先清空
        if (workerIds != null) {
            for (Integer wid : workerIds) {
                zoneWorkerMapper.insert(zoneId, wid);
            }
        }
        return Result.success();
    }
}