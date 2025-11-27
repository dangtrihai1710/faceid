import 'package:flutter/material.dart';
import '../../models/class_model.dart';
import '../../services/api_service.dart';
import 'dart:developer' as developer;

class ClassFormScreen extends StatefulWidget {
  final ClassModel? classModel;

  const ClassFormScreen({
    super.key,
    this.classModel,
  });

  @override
  State<ClassFormScreen> createState() => _ClassFormScreenState();
}

class _ClassFormScreenState extends State<ClassFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _subjectCodeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _roomController = TextEditingController();
  final _maxStudentsController = TextEditingController();
  final _academicYearController = TextEditingController();
  final _classCodeController = TextEditingController();
  final _classSequenceController = TextEditingController();

  String _selectedClassType = 'subject';
  String? _selectedInstructor;
  List<Map<String, dynamic>> _instructors = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.classModel != null) {
      _populateForm();
    } else {
      // Set default values for new classes
      _maxStudentsController.text = '30';
      _roomController.text = 'A101';
    }
    _loadInstructors();
  }

  void _populateForm() {
    final classItem = widget.classModel!;
    _nameController.text = classItem.name;
    _subjectCodeController.text = classItem.subject;
    _roomController.text = classItem.room;
    _descriptionController.text = classItem.description ?? '';
    _selectedClassType = classItem.classType;
    _selectedInstructor = classItem.instructor;
    _maxStudentsController.text = classItem.maxStudents?.toString() ?? '30';

    if (classItem.isAcademicClass) {
      _academicYearController.text = classItem.academicYear?.toString() ?? '';
      _classCodeController.text = classItem.classCode ?? '';
      _classSequenceController.text = classItem.classSequence?.toString() ?? '';
    }
  }

  Future<void> _loadInstructors() async {
    try {
      final token = ApiService.getToken();
      final instructors = await ApiService.getInstructors(token);
      setState(() {
        _instructors = instructors;
        // Set default instructor if none selected
        if (_selectedInstructor == null && instructors.isNotEmpty) {
          _selectedInstructor = instructors.first['user_id'];
        }
      });
    } catch (e) {
      developer.log('Error loading instructors: $e', name: 'ClassForm.instructors', level: 1000);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _subjectCodeController.dispose();
    _descriptionController.dispose();
    _roomController.dispose();
    _maxStudentsController.dispose();
    _academicYearController.dispose();
    _classCodeController.dispose();
    _classSequenceController.dispose();
    super.dispose();
  }

  bool _isEditing() => widget.classModel != null;

  Future<void> _saveClass() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final classData = {
        'name': _nameController.text.trim(),
        'class_type': _selectedClassType,
        'subject': _subjectCodeController.text.trim(),
        'instructor_id': _selectedInstructor,
        'room': _roomController.text.trim(),
        'description': _descriptionController.text.trim(),
        'max_students': _maxStudentsController.text.isNotEmpty
            ? int.tryParse(_maxStudentsController.text)
            : 30,
        'academic_year': _selectedClassType == 'academic' && _academicYearController.text.isNotEmpty
            ? int.tryParse(_academicYearController.text)
            : null,
        'class_code': _selectedClassType == 'academic' ? _classCodeController.text.trim() : null,
        'class_sequence': _selectedClassType == 'academic' && _classSequenceController.text.isNotEmpty
            ? int.tryParse(_classSequenceController.text)
            : null,
      };

      final token = ApiService.getToken();
      final result = _isEditing()
          ? await ApiService.updateClass(token, widget.classModel!.id, classData)
          : await ApiService.createClass(token, classData);

      if (mounted) {
        if (result['success'] == true) {
          _showSuccess(_isEditing() ? 'Cập nhật lớp học thành công' : 'Tạo lớp học thành công');
          Navigator.of(context).pop(true);
        } else {
          _showError(result['message'] ?? 'Lỗi khi lưu lớp học');
        }
      }
    } catch (e) {
      if (mounted) {
        _showError('Lỗi: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing() ? 'Sửa lớp học' : 'Thêm lớp học mới'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Class Type Selection
              DropdownButtonFormField<String>(
                initialValue: _selectedClassType,
                decoration: InputDecoration(
                  labelText: 'Loại lớp học',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.category),
                ),
                items: const [
                  DropdownMenuItem(value: 'academic', child: Text('Lớp theo khóa học')),
                  DropdownMenuItem(value: 'subject', child: Text('Lớp môn học')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedClassType = value!;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Class Name - Different validation based on type
              if (_selectedClassType == 'academic')
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Tên lớp (VD: 25ABC1)',
                    hintText: 'Định dạng: NămKhóaLớpSố',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.school),
                    helperText: 'VD: 25ABC1 (Năm 2025, Lớp ABC, Số 1)',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập tên lớp';
                    }
                    // Validate format for academic classes
                    if (!RegExp(r'^\d{2}[A-Za-z]{3}\d{1}$').hasMatch(value)) {
                      return 'Định dạng không hợp lệ. VD: 25ABC1';
                    }
                    return null;
                  },
                )
              else
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Tên lớp học',
                    hintText: 'VD: Lập trình Python cơ bản',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.book),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập tên lớp học';
                    }
                    return null;
                  },
                ),
              const SizedBox(height: 16),

              // Subject Code
              TextFormField(
                controller: _subjectCodeController,
                decoration: InputDecoration(
                  labelText: _selectedClassType == 'academic' ? 'Mã chung' : 'Mã môn học',
                  hintText: _selectedClassType == 'academic' ? 'GENERAL' : 'VD: CS101, PH201',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.code),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập mã';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Academic fields (for academic classes)
              if (_selectedClassType == 'academic') ...[
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _academicYearController,
                        decoration: InputDecoration(
                          labelText: 'Năm học',
                          hintText: 'VD: 25',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.calendar_today),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập năm học';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Vui lòng nhập số hợp lệ';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _classCodeController,
                        decoration: InputDecoration(
                          labelText: 'Mã lớp',
                          hintText: 'VD: ABC',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.class_),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập mã lớp';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _classSequenceController,
                  decoration: InputDecoration(
                    labelText: 'Số thứ tự',
                    hintText: 'VD: 1',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.tag),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập số thứ tự';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Vui lòng nhập số hợp lệ';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],

              // Instructor Selection
              if (_instructors.isNotEmpty)
                DropdownButtonFormField<String>(
                  initialValue: _selectedInstructor,
                  decoration: InputDecoration(
                    labelText: 'Giảng viên',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.person),
                  ),
                  items: _instructors.map((instructor) {
                    return DropdownMenuItem<String>(
                      value: instructor['user_id'],
                      child: Text(instructor['full_name'] ?? instructor['user_id'] ?? ''),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedInstructor = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng chọn giảng viên';
                    }
                    return null;
                  },
                ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Mô tả',
                  hintText: 'Mô tả về lớp học',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.description),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập mô tả';
                  }
                  if (value.trim().length < 10) {
                    return 'Mô tả phải có ít nhất 10 ký tự';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Room
              TextFormField(
                controller: _roomController,
                decoration: InputDecoration(
                  labelText: 'Phòng học',
                  hintText: 'VD: A101, B201',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.room),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập phòng học';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Max Students
              TextFormField(
                controller: _maxStudentsController,
                decoration: InputDecoration(
                  labelText: 'Số lượng sinh viên tối đa',
                  hintText: 'VD: 40',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.people),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập số lượng sinh viên';
                  }
                  final number = int.tryParse(value);
                  if (number == null || number <= 0) {
                    return 'Vui lòng nhập số hợp lệ lớn hơn 0';
                  }
                  if (number > 200) {
                    return 'Số lượng sinh viên không được quá 200';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveClass,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    _isLoading ? 'Đang lưu...' : (_isEditing() ? 'Cập nhật' : 'Thêm mới'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
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