使用 /FS 编译选项 (推荐):

/FS 选项告诉编译器在多线程编译时启用 "force-safe PDB" 模式，避免 PDB 文件写入冲突。

修改方法：

打开你的 Flutter 项目，找到 windows/CMakeLists.txt 文件。

在文件中找到 add_definitions 部分。

在 add_definitions 中加入 /FS 编译选项. 类似这样：

add_definitions(
  # Other definitions
    "/FS"
)
Use code with caution.
Cmake
保存 CMakeLists.txt 文件。