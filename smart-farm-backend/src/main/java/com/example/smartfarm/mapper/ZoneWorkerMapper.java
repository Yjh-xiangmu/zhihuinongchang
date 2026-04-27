package com.example.smartfarm.mapper;

import com.example.smartfarm.entity.User;
import org.apache.ibatis.annotations.*;
import java.util.List;

@Mapper
public interface ZoneWorkerMapper {

    // 查询某区域下的所有员工
    @Select("SELECT u.id, u.username, u.real_name, u.role FROM zone_worker zw " +
            "JOIN sys_user u ON zw.worker_id = u.id WHERE zw.zone_id = #{zoneId}")
    List<User> listWorkersByZone(Integer zoneId);

    // 查询某员工所属的区域id列表
    @Select("SELECT zone_id FROM zone_worker WHERE worker_id = #{workerId}")
    List<Integer> listZoneIdsByWorker(Integer workerId);

    // 新增关联
    @Insert("INSERT IGNORE INTO zone_worker(zone_id, worker_id) VALUES(#{zoneId}, #{workerId})")
    int insert(@Param("zoneId") Integer zoneId, @Param("workerId") Integer workerId);

    // 删除某区域的所有员工关联（用于重新设置）
    @Delete("DELETE FROM zone_worker WHERE zone_id = #{zoneId}")
    int deleteByZone(Integer zoneId);

    // 删除单条关联
    @Delete("DELETE FROM zone_worker WHERE zone_id = #{zoneId} AND worker_id = #{workerId}")
    int delete(@Param("zoneId") Integer zoneId, @Param("workerId") Integer workerId);
}