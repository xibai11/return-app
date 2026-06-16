import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth.dart';
import '../providers/records.dart';
import '../config.dart';

class RecordFormPage extends StatefulWidget {
  final int? editId;
  const RecordFormPage({super.key, this.editId});

  @override
  State<RecordFormPage> createState() => _RecordFormPageState();
}

class _RecordFormPageState extends State<RecordFormPage> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  final _orderNoCtrl = TextEditingController();
  final _customerCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _productCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController(text: '1');
  final _amountCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  final _remarkCtrl = TextEditingController();

  String _status = 'pending';
  String _reasonType = '质量问题';
  bool _isImportant = false;
  DateTime _returnDate = DateTime.now();

  final _reasonTypes = [
    '质量问题',
    '错发/漏发',
    '客户要求',
    '其他',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.editId != null) {
      _loadRecord();
    }
  }

  Future<void> _loadRecord() async {
    final records = context.read<RecordsProvider>().records;
    final Record? record = records.cast<Record?>().firstWhere(
      (r) => r?.id == widget.editId,
      orElse: () => null,
    );
    if (record == null) return;
    setState(() {
      _orderNoCtrl.text = record.orderNo ?? '';
      _customerCtrl.text = record.customerName ?? '';
      _phoneCtrl.text = record.customerPhone ?? '';
      _productCtrl.text = record.productName ?? '';
      _quantityCtrl.text = '${record.quantity ?? 1}';
      _amountCtrl.text = '${record.refundAmount ?? 0}';
      _reasonCtrl.text = record.refundReason ?? '';
      _remarkCtrl.text = record.remark ?? '';
      _status = record.status ?? 'pending';
      _isImportant = record.isImportant == true;
      if (record.returnDate != null) {
        _returnDate = DateTime.parse(record.returnDate);
      }
      if (_reasonTypes.contains(record.reasonType)) {
        _reasonType = record.reasonType;
      }
    });
  }

  @override
  void dispose() {
    _orderNoCtrl.dispose();
    _customerCtrl.dispose();
    _phoneCtrl.dispose();
    _productCtrl.dispose();
    _quantityCtrl.dispose();
    _amountCtrl.dispose();
    _reasonCtrl.dispose();
    _remarkCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _returnDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() => _returnDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final data = {
      'order_no': _orderNoCtrl.text.trim(),
      'customer_name': _customerCtrl.text.trim(),
      'customer_phone': _phoneCtrl.text.trim(),
      'product_name': _productCtrl.text.trim(),
      'quantity': int.tryParse(_quantityCtrl.text) ?? 1,
      'refund_amount': double.tryParse(_amountCtrl.text) ?? 0,
      'refund_reason': _reasonCtrl.text.trim(),
      'reason_type': _reasonType,
      'remark': _remarkCtrl.text.trim(),
      'status': _status,
      'is_important': _isImportant ? 1 : 0,
      'return_date': _returnDate.toIso8601String().split('T')[0],
    };

    bool ok;
    if (widget.editId != null) {
      ok = await context.read<RecordsProvider>().updateRecord(widget.editId!, data);
    } else {
      final rec = await context.read<RecordsProvider>().createRecord(data);
      ok = rec != null;
    }

    setState(() => _loading = false);
    if (ok && mounted) {
      Navigator.pop(context, true);
    } else if (mounted) {
      final err = context.read<RecordsProvider>().error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err ?? '提交失败'), backgroundColor: const Color(Config.dangerColor)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.editId != null ? '编辑记录' : '新增退货记录'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const SizedBox(
                    height: 16, width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('保存', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 基本信息
            _sectionTitle('基本信息'),
            const SizedBox(height: 8),
            _textField(_orderNoCtrl, '订单号 *', prefixIcon: Icons.receipt_outlined),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _textField(_customerCtrl, '客户姓名 *', prefixIcon: Icons.person_outline)),
                const SizedBox(width: 12),
                Expanded(child: _textField(_phoneCtrl, '联系电话', prefixIcon: Icons.phone_outlined)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _textField(_productCtrl, '商品名称 *', prefixIcon: Icons.inventory_2_outlined)),
                const SizedBox(width: 12),
                SizedBox(
                  width: 100,
                  child: _textField(_quantityCtrl, '数量 *', prefixIcon: Icons.tag, keyboardType: TextInputType.number),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _textField(_amountCtrl, '退款金额(元) *', prefixIcon: Icons.attach_money, keyboardType: TextInputType.number),

            const SizedBox(height: 20),
            _sectionTitle('退货信息'),
            const SizedBox(height: 8),

            // 退货日期
            GestureDetector(
              onTap: _selectDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(Config.bgColor),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(Config.borderColor)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 20, color: Color(Config.textSecondary)),
                    const SizedBox(width: 10),
                    Text(
                      '退货日期: ${_returnDate.toIso8601String().split('T')[0]}',
                      style: const TextStyle(fontSize: 15, color: Color(Config.textColor)),
                    ),
                    const Spacer(),
                    const Icon(Icons.arrow_drop_down, color: Color(Config.textSecondary)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 退款原因类型
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(Config.bgColor),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(Config.borderColor)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.help_outline, size: 20, color: Color(Config.textSecondary)),
                  const SizedBox(width: 10),
                  const Text('原因类型', style: TextStyle(fontSize: 15, color: Color(Config.textColor))),
                  const Spacer(),
                  DropdownButton<String>(
                    value: _reasonType,
                    underline: const SizedBox(),
                    isDense: true,
                    items: _reasonTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (v) => setState(() => _reasonType = v!),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _textField(_reasonCtrl, '详细原因 *', prefixIcon: Icons.comment_outlined, maxLines: 2),
            const SizedBox(height: 12),
            _textField(_remarkCtrl, '备注', prefixIcon: Icons.note_outlined, maxLines: 2),

            const SizedBox(height: 20),
            _sectionTitle('状态与优先级'),
            const SizedBox(height: 8),

            // 状态选择
            Wrap(
              spacing: 8,
              children: [
                _chip('pending', '待处理', const Color(Config.dangerColor)),
                _chip('processing', '处理中', const Color(Config.primaryColor)),
                _chip('completed', '已完成', const Color(Config.successColor)),
              ],
            ),
            const SizedBox(height: 12),

            // 重点标记
            GestureDetector(
              onTap: () => setState(() => _isImportant = !_isImportant),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: _isImportant ? const Color(Config.warningColor).withOpacity(0.1) : const Color(Config.bgColor),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isImportant ? const Color(Config.warningColor) : const Color(Config.borderColor),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isImportant ? Icons.star : Icons.star_outline,
                      color: _isImportant ? const Color(Config.warningColor) : const Color(Config.textSecondary),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '标记为重点退货',
                      style: TextStyle(
                        fontSize: 15,
                        color: _isImportant ? const Color(Config.warningColor) : const Color(Config.textColor),
                        fontWeight: _isImportant ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    const Spacer(),
                    Switch(
                      value: _isImportant,
                      activeColor: const Color(Config.warningColor),
                      onChanged: (v) => setState(() => _isImportant = v),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(Config.primaryColor),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: _loading
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      widget.editId != null ? '确认修改' : '提交记录',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: Color(Config.textColor),
      ),
    );
  }

  Widget _textField(
    TextEditingController ctrl,
    String label, {
    IconData? prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20) : null,
        filled: true,
        fillColor: const Color(Config.bgColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(Config.borderColor)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(Config.borderColor)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(Config.primaryColor)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      validator: (v) {
        if (label.contains('*')) {
          if (v == null || v.trim().isEmpty) return '必填';
        }
        return null;
      },
    );
  }

  Widget _chip(String value, String label, Color color) {
    final selected = _status == value;
    return GestureDetector(
      onTap: () => setState(() => _status = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? color : const Color(Config.borderColor)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: selected ? Colors.white : const Color(Config.textColor),
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
