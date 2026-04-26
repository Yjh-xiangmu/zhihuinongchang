package com.example.smartfarm.controller;

import com.example.smartfarm.common.Result;
import com.example.smartfarm.entity.User;
import com.example.smartfarm.mapper.UserMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import java.util.Map;

@RestController
@RequestMapping("/api")
@CrossOrigin // 允许跨域请求
public class AuthController {

    @Autowired
    private UserMapper userMapper;

    @PostMapping("/login")
    public Result login(@RequestBody Map<String, String> params) {
        String username = params.get("username");
        String password = params.get("password");
        String role = params.get("role");

        // 1. 去数据库查这个账号和角色匹配的人
        User user = userMapper.findByUsernameAndRole(username, role);

        if (user == null) {
            return Result.error("账号不存在或选择的角色错误");
        }

        // 2. 比对密码
        if (!user.getPassword().equals(password)) {
            return Result.error("密码错误");
        }

        // 3. 登录成功，把密码抹掉再返回给前端
        user.setPassword(null);
        return Result.success(user);
    }
}