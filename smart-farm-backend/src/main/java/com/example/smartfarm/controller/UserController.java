package com.example.smartfarm.controller;

import com.example.smartfarm.common.Result;
import com.example.smartfarm.entity.User;
import com.example.smartfarm.mapper.UserMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/users")
@CrossOrigin
public class UserController {

    @Autowired
    private UserMapper userMapper;

    @GetMapping("/list")
    public Result listAll() {
        return Result.success(userMapper.listAll());
    }

    @GetMapping("/list/role/{role}")
    public Result listByRole(@PathVariable String role) {
        return Result.success(userMapper.listByRole(role));
    }

    @PostMapping("/add")
    public Result add(@RequestBody User user) {
        // 默认密码
        if (user.getPassword() == null || user.getPassword().isEmpty()) {
            user.setPassword("123456");
        }
        userMapper.insert(user);
        user.setPassword(null);
        return Result.success(user);
    }

    @PutMapping("/update")
    public Result update(@RequestBody User user) {
        // 密码为空时不修改
        if (user.getPassword() != null && user.getPassword().isEmpty()) {
            user.setPassword(null);
        }
        userMapper.update(user);
        return Result.success();
    }

    @DeleteMapping("/delete/{id}")
    public Result delete(@PathVariable Integer id) {
        userMapper.deleteById(id);
        return Result.success();
    }
}
