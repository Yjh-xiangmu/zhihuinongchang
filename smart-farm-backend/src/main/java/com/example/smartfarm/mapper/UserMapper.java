package com.example.smartfarm.mapper;

import com.example.smartfarm.entity.User;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Select;

@Mapper
public interface UserMapper {
    @Select("SELECT * FROM sys_user WHERE username = #{username} AND role = #{role}")
    User findByUsernameAndRole(String username, String role);
}