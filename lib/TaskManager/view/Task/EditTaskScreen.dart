import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:btcuoiky/TaskManager/model/Task.dart';
import 'package:btcuoiky/TaskManager/model/User.dart';
import 'package:btcuoiky/TaskManager/db/UserDatabaseHelper.dart';

class EditTaskScreen extends StatefulWidget {
  final Task task;
  final String currentUserId;

  const EditTaskScreen({
    Key? key,
    required this.task,
    required this.currentUserId,
  }) : super(key: key);

  @override
  _EditTaskScreenState createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<EditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late String _status;
  late int _priority;
  late DateTime? _dueDate;
  late String? _assignedTo;
  late List<String> _attachments;
  List<User> _users = [];
  bool _isLoading = false;
  bool _isAdmin = false;
  bool _isCreator = false;

  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  final List<String> _statusOptions = ['To do', 'In progress', 'Done', 'Cancelled'];
  final List<int> _priorityOptions = [1, 2, 3];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _descriptionController = TextEditingController(text: widget.task.description);

    // Chuẩn hóa trạng thái để tránh lỗi dropdown
    String? taskStatus = widget.task.status;
    _status = _statusOptions.firstWhere(
          (option) => option.toLowerCase() == (taskStatus?.toLowerCase() ?? ''),
      orElse: () => _statusOptions.first,
    );

    _priority = widget.task.priority;
    _dueDate = widget.task.dueDate;
    _assignedTo = widget.task.assignedTo;
    _attachments = widget.task.attachments ?? [];
    _isCreator = widget.currentUserId == widget.task.createdBy;
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      User? currentUser = await UserDatabaseHelper.instance.getUserById(widget.currentUserId);
      _isAdmin = currentUser?.isAdmin ?? false;

      if (_isAdmin || _isCreator) {
        // Lấy danh sách tất cả người dùng trừ người dùng hiện tại
        List<User> users = await UserDatabaseHelper.instance.getAllUsersExcept(widget.currentUserId);

        // Nếu người được gán là người dùng hiện tại, thêm họ vào danh sách
        if (_assignedTo == widget.currentUserId && currentUser != null) {
          users.add(currentUser);
        }

        // Loại bỏ trùng lặp dựa trên user.id
        final userIds = <String>{};
        _users = users.where((user) {
          if (userIds.contains(user.id)) {
            return false;
          }
          userIds.add(user.id);
          return true;
        }).toList();

        // Nếu _assignedTo không khớp với bất kỳ user.id nào trong danh sách, đặt lại thành null
        if (_assignedTo != null && !_users.any((user) => user.id == _assignedTo)) {
          setState(() {
            _assignedTo = null;
          });
        }
      } else {
        _users = [];
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải danh sách người dùng: $e'), backgroundColor: Colors.red),
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

      if (result != null) {
        setState(() {
          _attachments.addAll(result.paths.where((path) => path != null).cast<String>());
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi chọn file: $e'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
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
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue.shade600,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue.shade600,
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

  void _handleSave() {
    if (_formKey.currentState!.validate()) {
      final updatedTask = widget.task.copyWith(
        title: _titleController.text,
        description: _descriptionController.text,
        status: _status,
        priority: _priority,
        dueDate: _dueDate,
        updatedAt: DateTime.now(),
        assignedTo: (_isAdmin || _isCreator) ? _assignedTo : widget.currentUserId,
        attachments: _attachments.isNotEmpty ? _attachments : null,
        completed: _status == 'Done',
      );
      Navigator.pop(context, updatedTask);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Chỉnh sửa công việc',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
        ),
      )
          : SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tiêu đề
              Text(
                'Tiêu đề công việc *',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                ),
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: 'Nhập tiêu đề công việc',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                style: TextStyle(fontSize: 16),
                readOnly: !(_isAdmin || _isCreator),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập tiêu đề';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),

              // Mô tả
              Text(
                'Mô tả',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                ),
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Nhập mô tả chi tiết...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                style: TextStyle(fontSize: 16),
                readOnly: !(_isAdmin || _isCreator),
              ),
              SizedBox(height: 20),

              // Trạng thái và Độ ưu tiên
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Trạng thái',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        SizedBox(height: 8),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButton<String>(
                            value: _status,
                            isExpanded: true,
                            underline: SizedBox(),
                            items: _statusOptions.map((status) {
                              return DropdownMenuItem<String>(value: status, child: Text(status));
                            }).toList(),
                            onChanged: (value) => setState(() => _status = value ?? _status),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Độ ưu tiên',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        SizedBox(height: 8),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButton<int>(
                            value: _priority,
                            isExpanded: true,
                            underline: SizedBox(),
                            items: _priorityOptions.map((priority) {
                              return DropdownMenuItem<int>(value: priority, child: Text('Mức $priority'));
                            }).toList(),
                            onChanged: (_isAdmin || _isCreator)
                                ? (value) => setState(() => _priority = value ?? _priority)
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),

              // Ngày đến hạn
              Text(
                'Ngày đến hạn',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                ),
              ),
              SizedBox(height: 8),
              InkWell(
                onTap: (_isAdmin || _isCreator) ? () => _selectDueDate(context) : null,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _dueDate == null ? 'Chọn ngày hạn' : _dateFormat.format(_dueDate!),
                        style: TextStyle(fontSize: 16),
                      ),
                      Icon(Icons.calendar_today, color: Colors.grey.shade600),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Gán cho người dùng (nếu admin hoặc creator)
              if (_users.isNotEmpty && (_isAdmin || _isCreator)) ...[
                Text(
                  'Gán cho người dùng',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButton<String>(
                    value: _assignedTo,
                    isExpanded: true,
                    hint: Text('Chọn người dùng'),
                    underline: SizedBox(),
                    items: [
                      DropdownMenuItem<String>(value: null, child: Text('Không gán')),
                      ..._users.map((user) {
                        return DropdownMenuItem<String>(
                          value: user.id,
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: Colors.blue.shade100,
                                child: Text(
                                  user.username[0].toUpperCase(),
                                  style: TextStyle(
                                    color: Colors.blue.shade800,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              SizedBox(width: 10),
                              Text(user.username),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                    onChanged: (_isAdmin || _isCreator) ? (value) => setState(() => _assignedTo = value) : null,
                  ),
                ),
                SizedBox(height: 20),
              ],

              // Tệp đính kèm
              Text(
                'Tệp đính kèm',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                ),
              ),
              SizedBox(height: 8),
              OutlinedButton(
                onPressed: _pickFiles,
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: Colors.blue.shade600),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.attach_file, color: Colors.blue.shade600),
                    SizedBox(width: 8),
                    Text(
                      'Thêm tệp đính kèm',
                      style: TextStyle(
                        color: Colors.blue.shade600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12),

              // Danh sách file đã chọn
              if (_attachments.isNotEmpty) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _attachments.asMap().entries.map((entry) {
                    final index = entry.key;
                    final path = entry.value;
                    return Container(
                      margin: EdgeInsets.only(bottom: 8),
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.file_present, color: Colors.blue.shade600),
                          SizedBox(width: 10),
                          Expanded(child: Text(path, overflow: TextOverflow.ellipsis)),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _removeAttachment(index),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: 12),
              ],

              // Nút lưu
              SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: _handleSave,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                    backgroundColor: Colors.blue.shade600,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Lưu',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}