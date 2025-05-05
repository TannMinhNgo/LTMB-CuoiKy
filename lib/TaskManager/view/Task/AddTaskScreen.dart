import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:btcuoiky/TaskManager/model/Task.dart';
import 'package:btcuoiky/TaskManager/model/User.dart';
import 'package:btcuoiky/TaskManager/db/TaskDatabaseHelper.dart';
import 'package:btcuoiky/TaskManager/db/UserDatabaseHelper.dart';

class AddTaskScreen extends StatefulWidget {
  final String currentUserId;

  const AddTaskScreen({Key? key, required this.currentUserId}) : super(key: key);

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _status = 'To do';
  int _priority = 1;
  DateTime? _dueDate;
  String? _assignedTo;
  List<String> _attachments = [];
  List<User> _users = [];
  bool _isLoading = false;
  bool _isAdmin = false;

  final List<String> _statusOptions = ['To do', 'In progress', 'Done', 'Cancelled'];
  final List<int> _priorityOptions = [1, 2, 3];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      User? currentUser = await UserDatabaseHelper.instance.getUserById(widget.currentUserId);
      _isAdmin = currentUser?.isAdmin ?? false;

      if (_isAdmin) {
        _users = await UserDatabaseHelper.instance.getAllUsers();
        _users.removeWhere((user) => user.id == widget.currentUserId);
      } else {
        _users = [];
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải user: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _attachments.addAll(result.paths.where((path) => path != null).cast<String>());
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi chọn file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeAttachment(int index) {
    setState(() {
      _attachments.removeAt(index);
    });
  }

  Future<void> _selectDueDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.grey.shade700,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey.shade700,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _dueDate) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  Future<void> _handleAddTask() async {
    if (_formKey.currentState!.validate()) {
      try {
        setState(() => _isLoading = true);
        final newTask = Task(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: _titleController.text,
          description: _descriptionController.text,
          status: _status,
          priority: _priority,
          dueDate: _dueDate,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          assignedTo: _isAdmin ? _assignedTo : widget.currentUserId,
          createdBy: widget.currentUserId,
          category: null,
          attachments: _attachments.isNotEmpty ? _attachments : null,
          completed: _status == 'Done',
        );
        await TaskDatabaseHelper.instance.createTask(newTask);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Thêm công việc thành công!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi thêm công việc: $e'), backgroundColor: Colors.red),
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
        title: Text(
          'Thêm công việc mới',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          TextButton(
            onPressed: _handleAddTask,
            child: Text(
              'Lưu',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 16),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Thông tin công việc',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Tiêu đề *',
                  hintText: 'Nhập tiêu đề công việc',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade700),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 12,
                  ),
                ),
                style: TextStyle(fontSize: 16),
                validator: (value) =>
                value == null || value.isEmpty
                    ? 'Vui lòng nhập tiêu đề'
                    : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Mô tả',
                  hintText: 'Nhập mô tả chi tiết công việc (nếu muốn)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade700),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 12,
                  ),
                ),
                maxLines: 3,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),
              Text(
                'Cài đặt công việc',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _status,
                      decoration: InputDecoration(
                        labelText: 'Trạng thái',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                          BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                          BorderSide(color: Colors.grey.shade700),
                        ),
                        contentPadding:
                        EdgeInsets.symmetric(horizontal: 12),
                      ),
                      items: _statusOptions
                          .map((status) => DropdownMenuItem<String>(
                        value: status,
                        child: Text(status),
                      ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _status = value);
                        }
                      },
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _priority,
                      decoration: InputDecoration(
                        labelText: 'Độ ưu tiên',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                          BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                          BorderSide(color: Colors.grey.shade700),
                        ),
                        contentPadding:
                        EdgeInsets.symmetric(horizontal: 12),
                      ),
                      items: _priorityOptions
                          .map((priority) => DropdownMenuItem<int>(
                        value: priority,
                        child: Text('Ưu tiên $priority'),
                      ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _priority = value);
                        }
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              InkWell(
                onTap: () => _selectDueDate(context),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Ngày đến hạn',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade700),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _dueDate == null
                            ? 'Chọn ngày'
                            : DateFormat('dd/MM/yyyy').format(_dueDate!),
                        style: TextStyle(fontSize: 16),
                      ),
                      Icon(Icons.arrow_drop_down, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              if (_users.isNotEmpty && _isAdmin)
                DropdownButtonFormField<String>(
                  value: _assignedTo,
                  decoration: InputDecoration(
                    labelText: 'Gán cho người dùng',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade700),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12),
                  ),
                  items: [
                    DropdownMenuItem<String>(
                        value: null, child: Text('Không gán')),
                    ..._users.map((user) => DropdownMenuItem<String>(
                      value: user.id,
                      child: Text(user.username),
                    )),
                  ],
                  onChanged: (value) => setState(() => _assignedTo = value),
                ),
              SizedBox(height: 20),
              Text(
                'Tệp đính kèm',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              SizedBox(height: 12),
              OutlinedButton(
                onPressed: _pickFiles,
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: Colors.grey.shade700),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  'Chọn tệp đính kèm',
                  style: TextStyle(
                      color: Colors.grey.shade700, fontSize: 16),
                ),
              ),
              SizedBox(height: 12),
              if (_attachments.isNotEmpty)
                ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _attachments.asMap().entries.map((entry) {
                      final index = entry.key;
                      final path = entry.value;
                      return Chip(
                        label: Text(
                          path.split('/').last,
                          style: TextStyle(fontSize: 14),
                        ),
                        deleteIcon: Icon(Icons.close, size: 18),
                        onDeleted: () => _removeAttachment(index),
                        backgroundColor: Colors.grey.shade100,
                        labelPadding:
                        EdgeInsets.symmetric(horizontal: 8),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 20),
                ],
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _handleAddTask,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.grey.shade700,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: Text(
                    'THÊM',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}