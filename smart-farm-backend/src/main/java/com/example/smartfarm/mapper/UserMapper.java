package com.example.smartfarm.mapper;

import com.example.smartfarm.entity.User;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Select;
import java.util.List;

@Mapper
public interface UserMapper {
    @Select("SELECT * FROM sys_user WHERE username = #{username} AND role = #{role}")
    User findByUsernameAndRole(String username, String role);

    List<User> listAll();
    List<User> listByRole(String role);
    User getById(Integer id);
    int insert(User user);
    int update(User user);
    int deleteById(Integer id);
}
