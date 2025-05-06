import 'package:flutter/material.dart';
import 'package:btcuoiky/TaskManager/view/Task/AddTaskScreen.dart';
import 'package:btcuoiky/TaskManager/view/Task/EditTaskScreen.dart';
import 'package:btcuoiky/TaskManager/model/Task.dart';
import 'package:btcuoiky/TaskManager/view/Task/TaskDetailScreen.dart';
import 'package:btcuoiky/TaskManager/view/Authentication/LoginScreen.dart';
import 'package:btcuoiky/TaskManager/db/TaskDatabaseHelper.dart';
import 'package:btcuoiky/TaskManager/db/UserDatabaseHelper.dart';
import 'package:shared_preferences/shared_preferences.dart';
class TaskListScreen extends StatefulWidget {
  final String currentUserId;

  const TaskListScreen({Key? key, required this.currentUserId}) : super(key: key);

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}
class _TaskListScreenState extends State<TaskListScreen> {
  List<Task> tasks = [];
  List<Task> filteredTasks = [];
  bool isGrid = false;
  String selectedStatus = 'Tất cả';
  String searchKeyword = '';
  bool _isLoading = false;
  bool _dbInitialized = false;
  bool _isAdmin = false;
  @override
  void initState() {
    super.initState();
    _initializeDatabase();
  }

  Future<void> _initializeDatabase() async {
    try {
      setState(() => _isLoading = true);
      await TaskDatabaseHelper.instance.database;
      setState(() => _dbInitialized = true);

      final user = await UserDatabaseHelper.instance.getUserById(widget.currentUserId);
      _isAdmin = user?.isAdmin ?? false;

      await _loadTasks();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khởi tạo database: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
  Future<void> _loadTasks() async {
    if (!_dbInitialized) return;

    try {
      setState(() => _isLoading = true);

      if (_isAdmin) {
        tasks = await TaskDatabaseHelper.instance.getAllTasks();
      } else {
        tasks = await TaskDatabaseHelper.instance.getTasksByUser(widget.currentUserId);
      }

      _applyFilters();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải công việc: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    setState(() {
      filteredTasks = tasks.where((task) {
        final matchesStatus = selectedStatus == 'Tất cả' || task.status == selectedStatus;
        final matchesSearch = searchKeyword.isEmpty ||
            task.title.toLowerCase().contains(searchKeyword.toLowerCase()) ||
            task.description.toLowerCase().contains(searchKeyword.toLowerCase());
        return matchesStatus && matchesSearch;
      }).toList();

      filteredTasks.sort((a, b) => b.priority.compareTo(a.priority));
    });
  }

  Future<void> _deleteTask(String taskId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa công việc này không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Xóa', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        setState(() => _isLoading = true);

        final task = tasks.firstWhere((task) => task.id == taskId);

        if (!_isAdmin && task.createdBy != widget.currentUserId) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bạn không thể xóa công việc do Admin tạo.'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => _isLoading = false);
          return;
        }

        await TaskDatabaseHelper.instance.deleteTask(taskId);
        await _loadTasks();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi xóa task: $e')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Danh sách Công việc',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.blue.shade700,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadTasks,
          ),
          IconButton(
            icon: Icon(isGrid ? Icons.view_list : Icons.grid_view, color: Colors.white),
            onPressed: () => setState(() => isGrid = !isGrid),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                _showLogoutDialog();
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: const [
                    Icon(Icons.exit_to_app, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Đăng xuất'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.blue))
          : Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
              child: Row(
                children: [
                  Icon(
                    _isAdmin ? Icons.shield : Icons.person,
                    color: _isAdmin ? Colors.red : Colors.blue.shade700,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isAdmin ? 'Quyền: Admin' : 'Quyền: Người dùng',
                    style: TextStyle(
                      color: _isAdmin ? Colors.red : Colors.blue.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm công việc...',
                  prefixIcon: const Icon(Icons.search, color: Colors.blue),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: Colors.blue.shade100),
                  ),
                ),
                onChanged: (value) {
                  searchKeyword = value;
                  _applyFilters();
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: DropdownButtonFormField<String>(
                value: selectedStatus,
                decoration: InputDecoration(
                  labelText: 'Lọc theo trạng thái',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: Colors.blue.shade100),
                  ),
                ),
                items: ['Tất cả', 'To do', 'In progress', 'Done', 'Cancelled']
                    .map((status) => DropdownMenuItem<String>(
                  value: status,
                  child: Text(status),
                ))
                    .toList(),
                onChanged: (value) {
                  selectedStatus = value!;
                  _applyFilters();
                },
              ),
            ),
            Expanded(
              child: isGrid ? _buildTaskGridView() : _buildTaskListView(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => AddTaskScreen(currentUserId: widget.currentUserId)),
          );
          if (result == true) await _loadTasks();
        },
        child: const Icon(Icons.add, color: Colors.white),
        backgroundColor: Colors.blue.shade700,
        elevation: 4,
      ),
    );
  }

  Widget _buildTaskListView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredTasks.length,
      itemBuilder: (context, index) {
        final task = filteredTasks[index];
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(bottom: 12),
          child: Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: _getPriorityColor(task.priority),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              title: Text(
                task.title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    'Trạng thái: ${task.status}',
                    style: TextStyle(color: _getStatusColor(task.status), fontSize: 14),
                  ),
                  Text(
                    'Ưu tiên: ${_priorityText(task.priority)}',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                  ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () async {
                      final updatedTask = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditTaskScreen(
                              task: task, currentUserId: widget.currentUserId),
                        ),
                      );
                      if (updatedTask != null) {
                        await TaskDatabaseHelper.instance.updateTask(updatedTask);
                        await _loadTasks();
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteTask(task.id),
                  ),
                ],
              ),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TaskDetailScreen(task: task)),
                );
                await _loadTasks();
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildTaskGridView() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2 / 3, // Giảm childAspectRatio để kéo dài vừa phải
      ),
      itemCount: filteredTasks.length,
      itemBuilder: (context, index) {
        final task = filteredTasks[index];
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          child: GestureDetector(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => TaskDetailScreen(task: task)),
              );
              await _loadTasks();
            },
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: _getPriorityColor(task.priority),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title text
                    Text(
                      task.title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Status text
                    Text(
                      'Trạng thái: ${task.status}',
                      style: TextStyle(
                        fontSize: 12, color: _getStatusColor(task.status),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Priority text
                    Text(
                      'Ưu tiên: ${_priorityText(task.priority)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 8), // Thêm khoảng cách giữa các phần

                    // Thêm khoảng cách và điều chỉnh phần icon
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20, color: Colors.blue),
                          onPressed: () async {
                            final updatedTask = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditTaskScreen(
                                    task: task, currentUserId: widget.currentUserId),
                              ),
                            );
                            if (updatedTask != null) {
                              await TaskDatabaseHelper.instance
                                  .updateTask(updatedTask);
                              await _loadTasks();
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                          onPressed: () => _deleteTask(task.id),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Hủy')),
          TextButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
              );
            },
            child: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(int priority) {
    switch (priority) {
      case 1:
        return Colors.green.shade200; // Green for low priority
      case 2:
        return Colors.yellow.shade200; // Yellow for medium priority
      case 3:
        return Colors.red.shade200; // Red for high priority
      default:
        return Colors.grey.shade200;
    }
  }

  String _priorityText(int priority) {
    switch (priority) {
      case 1:
        return 'Thấp';
      case 2:
        return 'Trung bình';
      case 3:
        return 'Cao';
      default:
        return 'Không xác định';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'To do':
        return Colors.grey.shade700;
      case 'In progress':
        return Colors.cyanAccent.shade700;
      case 'Done':
        return Colors.green.shade700;
      case 'Cancelled':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade700;
    }
  }
}