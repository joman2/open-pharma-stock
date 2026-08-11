// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $InventorySessionsTable extends InventorySessions
    with TableInfo<$InventorySessionsTable, InventorySessionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InventorySessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _barcodeQuantityPromptEnabledMeta =
      const VerificationMeta('barcodeQuantityPromptEnabled');
  @override
  late final GeneratedColumn<bool> barcodeQuantityPromptEnabled =
      GeneratedColumn<bool>(
        'barcode_quantity_prompt_enabled',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("barcode_quantity_prompt_enabled" IN (0, 1))',
        ),
        defaultValue: const Constant(false),
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    createdAt,
    updatedAt,
    barcodeQuantityPromptEnabled,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'inventory_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<InventorySessionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('barcode_quantity_prompt_enabled')) {
      context.handle(
        _barcodeQuantityPromptEnabledMeta,
        barcodeQuantityPromptEnabled.isAcceptableOrUnknown(
          data['barcode_quantity_prompt_enabled']!,
          _barcodeQuantityPromptEnabledMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InventorySessionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InventorySessionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      barcodeQuantityPromptEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}barcode_quantity_prompt_enabled'],
      )!,
    );
  }

  @override
  $InventorySessionsTable createAlias(String alias) {
    return $InventorySessionsTable(attachedDatabase, alias);
  }
}

class InventorySessionRow extends DataClass
    implements Insertable<InventorySessionRow> {
  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool barcodeQuantityPromptEnabled;
  const InventorySessionRow({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    required this.barcodeQuantityPromptEnabled,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['barcode_quantity_prompt_enabled'] = Variable<bool>(
      barcodeQuantityPromptEnabled,
    );
    return map;
  }

  InventorySessionsCompanion toCompanion(bool nullToAbsent) {
    return InventorySessionsCompanion(
      id: Value(id),
      name: Value(name),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      barcodeQuantityPromptEnabled: Value(barcodeQuantityPromptEnabled),
    );
  }

  factory InventorySessionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InventorySessionRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      barcodeQuantityPromptEnabled: serializer.fromJson<bool>(
        json['barcodeQuantityPromptEnabled'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'barcodeQuantityPromptEnabled': serializer.toJson<bool>(
        barcodeQuantityPromptEnabled,
      ),
    };
  }

  InventorySessionRow copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? barcodeQuantityPromptEnabled,
  }) => InventorySessionRow(
    id: id ?? this.id,
    name: name ?? this.name,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    barcodeQuantityPromptEnabled:
        barcodeQuantityPromptEnabled ?? this.barcodeQuantityPromptEnabled,
  );
  InventorySessionRow copyWithCompanion(InventorySessionsCompanion data) {
    return InventorySessionRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      barcodeQuantityPromptEnabled: data.barcodeQuantityPromptEnabled.present
          ? data.barcodeQuantityPromptEnabled.value
          : this.barcodeQuantityPromptEnabled,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InventorySessionRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('barcodeQuantityPromptEnabled: $barcodeQuantityPromptEnabled')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, createdAt, updatedAt, barcodeQuantityPromptEnabled);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InventorySessionRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.barcodeQuantityPromptEnabled ==
              this.barcodeQuantityPromptEnabled);
}

class InventorySessionsCompanion extends UpdateCompanion<InventorySessionRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<bool> barcodeQuantityPromptEnabled;
  final Value<int> rowid;
  const InventorySessionsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.barcodeQuantityPromptEnabled = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InventorySessionsCompanion.insert({
    required String id,
    required String name,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.barcodeQuantityPromptEnabled = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<InventorySessionRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<bool>? barcodeQuantityPromptEnabled,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (barcodeQuantityPromptEnabled != null)
        'barcode_quantity_prompt_enabled': barcodeQuantityPromptEnabled,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InventorySessionsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<bool>? barcodeQuantityPromptEnabled,
    Value<int>? rowid,
  }) {
    return InventorySessionsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      barcodeQuantityPromptEnabled:
          barcodeQuantityPromptEnabled ?? this.barcodeQuantityPromptEnabled,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (barcodeQuantityPromptEnabled.present) {
      map['barcode_quantity_prompt_enabled'] = Variable<bool>(
        barcodeQuantityPromptEnabled.value,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InventorySessionsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write(
            'barcodeQuantityPromptEnabled: $barcodeQuantityPromptEnabled, ',
          )
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ScanEventsTable extends ScanEvents
    with TableInfo<$ScanEventsTable, ScanEventRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ScanEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES inventory_sessions (id)',
    ),
  );
  static const VerificationMeta _productCodeMeta = const VerificationMeta(
    'productCode',
  );
  @override
  late final GeneratedColumn<String> productCode = GeneratedColumn<String>(
    'product_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _codeTypeMeta = const VerificationMeta(
    'codeType',
  );
  @override
  late final GeneratedColumn<String> codeType = GeneratedColumn<String>(
    'code_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rawMeta = const VerificationMeta('raw');
  @override
  late final GeneratedColumn<String> raw = GeneratedColumn<String>(
    'raw',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serialNumberMeta = const VerificationMeta(
    'serialNumber',
  );
  @override
  late final GeneratedColumn<String> serialNumber = GeneratedColumn<String>(
    'serial_number',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lotMeta = const VerificationMeta('lot');
  @override
  late final GeneratedColumn<String> lot = GeneratedColumn<String>(
    'lot',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _expiryMeta = const VerificationMeta('expiry');
  @override
  late final GeneratedColumn<String> expiry = GeneratedColumn<String>(
    'expiry',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    productCode,
    codeType,
    raw,
    serialNumber,
    lot,
    expiry,
    createdAt,
    isDeleted,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'scan_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<ScanEventRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('product_code')) {
      context.handle(
        _productCodeMeta,
        productCode.isAcceptableOrUnknown(
          data['product_code']!,
          _productCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_productCodeMeta);
    }
    if (data.containsKey('code_type')) {
      context.handle(
        _codeTypeMeta,
        codeType.isAcceptableOrUnknown(data['code_type']!, _codeTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_codeTypeMeta);
    }
    if (data.containsKey('raw')) {
      context.handle(
        _rawMeta,
        raw.isAcceptableOrUnknown(data['raw']!, _rawMeta),
      );
    } else if (isInserting) {
      context.missing(_rawMeta);
    }
    if (data.containsKey('serial_number')) {
      context.handle(
        _serialNumberMeta,
        serialNumber.isAcceptableOrUnknown(
          data['serial_number']!,
          _serialNumberMeta,
        ),
      );
    }
    if (data.containsKey('lot')) {
      context.handle(
        _lotMeta,
        lot.isAcceptableOrUnknown(data['lot']!, _lotMeta),
      );
    }
    if (data.containsKey('expiry')) {
      context.handle(
        _expiryMeta,
        expiry.isAcceptableOrUnknown(data['expiry']!, _expiryMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ScanEventRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ScanEventRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      productCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_code'],
      )!,
      codeType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code_type'],
      )!,
      raw: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw'],
      )!,
      serialNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}serial_number'],
      ),
      lot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lot'],
      ),
      expiry: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}expiry'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
    );
  }

  @override
  $ScanEventsTable createAlias(String alias) {
    return $ScanEventsTable(attachedDatabase, alias);
  }
}

class ScanEventRow extends DataClass implements Insertable<ScanEventRow> {
  final String id;
  final String sessionId;
  final String productCode;
  final String codeType;
  final String raw;
  final String? serialNumber;
  final String? lot;
  final String? expiry;
  final DateTime createdAt;
  final bool isDeleted;
  const ScanEventRow({
    required this.id,
    required this.sessionId,
    required this.productCode,
    required this.codeType,
    required this.raw,
    this.serialNumber,
    this.lot,
    this.expiry,
    required this.createdAt,
    required this.isDeleted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['session_id'] = Variable<String>(sessionId);
    map['product_code'] = Variable<String>(productCode);
    map['code_type'] = Variable<String>(codeType);
    map['raw'] = Variable<String>(raw);
    if (!nullToAbsent || serialNumber != null) {
      map['serial_number'] = Variable<String>(serialNumber);
    }
    if (!nullToAbsent || lot != null) {
      map['lot'] = Variable<String>(lot);
    }
    if (!nullToAbsent || expiry != null) {
      map['expiry'] = Variable<String>(expiry);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['is_deleted'] = Variable<bool>(isDeleted);
    return map;
  }

  ScanEventsCompanion toCompanion(bool nullToAbsent) {
    return ScanEventsCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      productCode: Value(productCode),
      codeType: Value(codeType),
      raw: Value(raw),
      serialNumber: serialNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(serialNumber),
      lot: lot == null && nullToAbsent ? const Value.absent() : Value(lot),
      expiry: expiry == null && nullToAbsent
          ? const Value.absent()
          : Value(expiry),
      createdAt: Value(createdAt),
      isDeleted: Value(isDeleted),
    );
  }

  factory ScanEventRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ScanEventRow(
      id: serializer.fromJson<String>(json['id']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      productCode: serializer.fromJson<String>(json['productCode']),
      codeType: serializer.fromJson<String>(json['codeType']),
      raw: serializer.fromJson<String>(json['raw']),
      serialNumber: serializer.fromJson<String?>(json['serialNumber']),
      lot: serializer.fromJson<String?>(json['lot']),
      expiry: serializer.fromJson<String?>(json['expiry']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sessionId': serializer.toJson<String>(sessionId),
      'productCode': serializer.toJson<String>(productCode),
      'codeType': serializer.toJson<String>(codeType),
      'raw': serializer.toJson<String>(raw),
      'serialNumber': serializer.toJson<String?>(serialNumber),
      'lot': serializer.toJson<String?>(lot),
      'expiry': serializer.toJson<String?>(expiry),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'isDeleted': serializer.toJson<bool>(isDeleted),
    };
  }

  ScanEventRow copyWith({
    String? id,
    String? sessionId,
    String? productCode,
    String? codeType,
    String? raw,
    Value<String?> serialNumber = const Value.absent(),
    Value<String?> lot = const Value.absent(),
    Value<String?> expiry = const Value.absent(),
    DateTime? createdAt,
    bool? isDeleted,
  }) => ScanEventRow(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    productCode: productCode ?? this.productCode,
    codeType: codeType ?? this.codeType,
    raw: raw ?? this.raw,
    serialNumber: serialNumber.present ? serialNumber.value : this.serialNumber,
    lot: lot.present ? lot.value : this.lot,
    expiry: expiry.present ? expiry.value : this.expiry,
    createdAt: createdAt ?? this.createdAt,
    isDeleted: isDeleted ?? this.isDeleted,
  );
  ScanEventRow copyWithCompanion(ScanEventsCompanion data) {
    return ScanEventRow(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      productCode: data.productCode.present
          ? data.productCode.value
          : this.productCode,
      codeType: data.codeType.present ? data.codeType.value : this.codeType,
      raw: data.raw.present ? data.raw.value : this.raw,
      serialNumber: data.serialNumber.present
          ? data.serialNumber.value
          : this.serialNumber,
      lot: data.lot.present ? data.lot.value : this.lot,
      expiry: data.expiry.present ? data.expiry.value : this.expiry,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ScanEventRow(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('productCode: $productCode, ')
          ..write('codeType: $codeType, ')
          ..write('raw: $raw, ')
          ..write('serialNumber: $serialNumber, ')
          ..write('lot: $lot, ')
          ..write('expiry: $expiry, ')
          ..write('createdAt: $createdAt, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sessionId,
    productCode,
    codeType,
    raw,
    serialNumber,
    lot,
    expiry,
    createdAt,
    isDeleted,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ScanEventRow &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.productCode == this.productCode &&
          other.codeType == this.codeType &&
          other.raw == this.raw &&
          other.serialNumber == this.serialNumber &&
          other.lot == this.lot &&
          other.expiry == this.expiry &&
          other.createdAt == this.createdAt &&
          other.isDeleted == this.isDeleted);
}

class ScanEventsCompanion extends UpdateCompanion<ScanEventRow> {
  final Value<String> id;
  final Value<String> sessionId;
  final Value<String> productCode;
  final Value<String> codeType;
  final Value<String> raw;
  final Value<String?> serialNumber;
  final Value<String?> lot;
  final Value<String?> expiry;
  final Value<DateTime> createdAt;
  final Value<bool> isDeleted;
  final Value<int> rowid;
  const ScanEventsCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.productCode = const Value.absent(),
    this.codeType = const Value.absent(),
    this.raw = const Value.absent(),
    this.serialNumber = const Value.absent(),
    this.lot = const Value.absent(),
    this.expiry = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ScanEventsCompanion.insert({
    required String id,
    required String sessionId,
    required String productCode,
    required String codeType,
    required String raw,
    this.serialNumber = const Value.absent(),
    this.lot = const Value.absent(),
    this.expiry = const Value.absent(),
    required DateTime createdAt,
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sessionId = Value(sessionId),
       productCode = Value(productCode),
       codeType = Value(codeType),
       raw = Value(raw),
       createdAt = Value(createdAt);
  static Insertable<ScanEventRow> custom({
    Expression<String>? id,
    Expression<String>? sessionId,
    Expression<String>? productCode,
    Expression<String>? codeType,
    Expression<String>? raw,
    Expression<String>? serialNumber,
    Expression<String>? lot,
    Expression<String>? expiry,
    Expression<DateTime>? createdAt,
    Expression<bool>? isDeleted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (productCode != null) 'product_code': productCode,
      if (codeType != null) 'code_type': codeType,
      if (raw != null) 'raw': raw,
      if (serialNumber != null) 'serial_number': serialNumber,
      if (lot != null) 'lot': lot,
      if (expiry != null) 'expiry': expiry,
      if (createdAt != null) 'created_at': createdAt,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ScanEventsCompanion copyWith({
    Value<String>? id,
    Value<String>? sessionId,
    Value<String>? productCode,
    Value<String>? codeType,
    Value<String>? raw,
    Value<String?>? serialNumber,
    Value<String?>? lot,
    Value<String?>? expiry,
    Value<DateTime>? createdAt,
    Value<bool>? isDeleted,
    Value<int>? rowid,
  }) {
    return ScanEventsCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      productCode: productCode ?? this.productCode,
      codeType: codeType ?? this.codeType,
      raw: raw ?? this.raw,
      serialNumber: serialNumber ?? this.serialNumber,
      lot: lot ?? this.lot,
      expiry: expiry ?? this.expiry,
      createdAt: createdAt ?? this.createdAt,
      isDeleted: isDeleted ?? this.isDeleted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (productCode.present) {
      map['product_code'] = Variable<String>(productCode.value);
    }
    if (codeType.present) {
      map['code_type'] = Variable<String>(codeType.value);
    }
    if (raw.present) {
      map['raw'] = Variable<String>(raw.value);
    }
    if (serialNumber.present) {
      map['serial_number'] = Variable<String>(serialNumber.value);
    }
    if (lot.present) {
      map['lot'] = Variable<String>(lot.value);
    }
    if (expiry.present) {
      map['expiry'] = Variable<String>(expiry.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ScanEventsCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('productCode: $productCode, ')
          ..write('codeType: $codeType, ')
          ..write('raw: $raw, ')
          ..write('serialNumber: $serialNumber, ')
          ..write('lot: $lot, ')
          ..write('expiry: $expiry, ')
          ..write('createdAt: $createdAt, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MedicationCatalogEntriesTable extends MedicationCatalogEntries
    with TableInfo<$MedicationCatalogEntriesTable, MedicationCatalogEntryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MedicationCatalogEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceNameMeta = const VerificationMeta(
    'sourceName',
  );
  @override
  late final GeneratedColumn<String> sourceName = GeneratedColumn<String>(
    'source_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourcePriorityMeta = const VerificationMeta(
    'sourcePriority',
  );
  @override
  late final GeneratedColumn<int> sourcePriority = GeneratedColumn<int>(
    'source_priority',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceRecordIdMeta = const VerificationMeta(
    'sourceRecordId',
  );
  @override
  late final GeneratedColumn<String> sourceRecordId = GeneratedColumn<String>(
    'source_record_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _canonicalCodeMeta = const VerificationMeta(
    'canonicalCode',
  );
  @override
  late final GeneratedColumn<String> canonicalCode = GeneratedColumn<String>(
    'canonical_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activeSubstanceMeta = const VerificationMeta(
    'activeSubstance',
  );
  @override
  late final GeneratedColumn<String> activeSubstance = GeneratedColumn<String>(
    'active_substance',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _strengthMeta = const VerificationMeta(
    'strength',
  );
  @override
  late final GeneratedColumn<String> strength = GeneratedColumn<String>(
    'strength',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pharmaceuticalFormMeta =
      const VerificationMeta('pharmaceuticalForm');
  @override
  late final GeneratedColumn<String> pharmaceuticalForm =
      GeneratedColumn<String>(
        'pharmaceutical_form',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _presentationMeta = const VerificationMeta(
    'presentation',
  );
  @override
  late final GeneratedColumn<String> presentation = GeneratedColumn<String>(
    'presentation',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _holderMeta = const VerificationMeta('holder');
  @override
  late final GeneratedColumn<String> holder = GeneratedColumn<String>(
    'holder',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _leafletUrlMeta = const VerificationMeta(
    'leafletUrl',
  );
  @override
  late final GeneratedColumn<String> leafletUrl = GeneratedColumn<String>(
    'leaflet_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rcmUrlMeta = const VerificationMeta('rcmUrl');
  @override
  late final GeneratedColumn<String> rcmUrl = GeneratedColumn<String>(
    'rcm_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceUrlMeta = const VerificationMeta(
    'sourceUrl',
  );
  @override
  late final GeneratedColumn<String> sourceUrl = GeneratedColumn<String>(
    'source_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _imageUrlMeta = const VerificationMeta(
    'imageUrl',
  );
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
    'image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sourceName,
    sourcePriority,
    sourceRecordId,
    canonicalCode,
    displayName,
    activeSubstance,
    strength,
    pharmaceuticalForm,
    presentation,
    holder,
    leafletUrl,
    rcmUrl,
    sourceUrl,
    imageUrl,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'medication_catalog_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<MedicationCatalogEntryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('source_name')) {
      context.handle(
        _sourceNameMeta,
        sourceName.isAcceptableOrUnknown(data['source_name']!, _sourceNameMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceNameMeta);
    }
    if (data.containsKey('source_priority')) {
      context.handle(
        _sourcePriorityMeta,
        sourcePriority.isAcceptableOrUnknown(
          data['source_priority']!,
          _sourcePriorityMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sourcePriorityMeta);
    }
    if (data.containsKey('source_record_id')) {
      context.handle(
        _sourceRecordIdMeta,
        sourceRecordId.isAcceptableOrUnknown(
          data['source_record_id']!,
          _sourceRecordIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sourceRecordIdMeta);
    }
    if (data.containsKey('canonical_code')) {
      context.handle(
        _canonicalCodeMeta,
        canonicalCode.isAcceptableOrUnknown(
          data['canonical_code']!,
          _canonicalCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_canonicalCodeMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('active_substance')) {
      context.handle(
        _activeSubstanceMeta,
        activeSubstance.isAcceptableOrUnknown(
          data['active_substance']!,
          _activeSubstanceMeta,
        ),
      );
    }
    if (data.containsKey('strength')) {
      context.handle(
        _strengthMeta,
        strength.isAcceptableOrUnknown(data['strength']!, _strengthMeta),
      );
    }
    if (data.containsKey('pharmaceutical_form')) {
      context.handle(
        _pharmaceuticalFormMeta,
        pharmaceuticalForm.isAcceptableOrUnknown(
          data['pharmaceutical_form']!,
          _pharmaceuticalFormMeta,
        ),
      );
    }
    if (data.containsKey('presentation')) {
      context.handle(
        _presentationMeta,
        presentation.isAcceptableOrUnknown(
          data['presentation']!,
          _presentationMeta,
        ),
      );
    }
    if (data.containsKey('holder')) {
      context.handle(
        _holderMeta,
        holder.isAcceptableOrUnknown(data['holder']!, _holderMeta),
      );
    }
    if (data.containsKey('leaflet_url')) {
      context.handle(
        _leafletUrlMeta,
        leafletUrl.isAcceptableOrUnknown(data['leaflet_url']!, _leafletUrlMeta),
      );
    }
    if (data.containsKey('rcm_url')) {
      context.handle(
        _rcmUrlMeta,
        rcmUrl.isAcceptableOrUnknown(data['rcm_url']!, _rcmUrlMeta),
      );
    }
    if (data.containsKey('source_url')) {
      context.handle(
        _sourceUrlMeta,
        sourceUrl.isAcceptableOrUnknown(data['source_url']!, _sourceUrlMeta),
      );
    }
    if (data.containsKey('image_url')) {
      context.handle(
        _imageUrlMeta,
        imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MedicationCatalogEntryRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MedicationCatalogEntryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sourceName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_name'],
      )!,
      sourcePriority: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}source_priority'],
      )!,
      sourceRecordId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_record_id'],
      )!,
      canonicalCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}canonical_code'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      activeSubstance: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}active_substance'],
      ),
      strength: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}strength'],
      ),
      pharmaceuticalForm: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pharmaceutical_form'],
      ),
      presentation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}presentation'],
      ),
      holder: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}holder'],
      ),
      leafletUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}leaflet_url'],
      ),
      rcmUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rcm_url'],
      ),
      sourceUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_url'],
      ),
      imageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_url'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $MedicationCatalogEntriesTable createAlias(String alias) {
    return $MedicationCatalogEntriesTable(attachedDatabase, alias);
  }
}

class MedicationCatalogEntryRow extends DataClass
    implements Insertable<MedicationCatalogEntryRow> {
  final String id;
  final String sourceName;
  final int sourcePriority;
  final String sourceRecordId;
  final String canonicalCode;
  final String displayName;
  final String? activeSubstance;
  final String? strength;
  final String? pharmaceuticalForm;
  final String? presentation;
  final String? holder;
  final String? leafletUrl;
  final String? rcmUrl;
  final String? sourceUrl;
  final String? imageUrl;
  final DateTime updatedAt;
  const MedicationCatalogEntryRow({
    required this.id,
    required this.sourceName,
    required this.sourcePriority,
    required this.sourceRecordId,
    required this.canonicalCode,
    required this.displayName,
    this.activeSubstance,
    this.strength,
    this.pharmaceuticalForm,
    this.presentation,
    this.holder,
    this.leafletUrl,
    this.rcmUrl,
    this.sourceUrl,
    this.imageUrl,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['source_name'] = Variable<String>(sourceName);
    map['source_priority'] = Variable<int>(sourcePriority);
    map['source_record_id'] = Variable<String>(sourceRecordId);
    map['canonical_code'] = Variable<String>(canonicalCode);
    map['display_name'] = Variable<String>(displayName);
    if (!nullToAbsent || activeSubstance != null) {
      map['active_substance'] = Variable<String>(activeSubstance);
    }
    if (!nullToAbsent || strength != null) {
      map['strength'] = Variable<String>(strength);
    }
    if (!nullToAbsent || pharmaceuticalForm != null) {
      map['pharmaceutical_form'] = Variable<String>(pharmaceuticalForm);
    }
    if (!nullToAbsent || presentation != null) {
      map['presentation'] = Variable<String>(presentation);
    }
    if (!nullToAbsent || holder != null) {
      map['holder'] = Variable<String>(holder);
    }
    if (!nullToAbsent || leafletUrl != null) {
      map['leaflet_url'] = Variable<String>(leafletUrl);
    }
    if (!nullToAbsent || rcmUrl != null) {
      map['rcm_url'] = Variable<String>(rcmUrl);
    }
    if (!nullToAbsent || sourceUrl != null) {
      map['source_url'] = Variable<String>(sourceUrl);
    }
    if (!nullToAbsent || imageUrl != null) {
      map['image_url'] = Variable<String>(imageUrl);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  MedicationCatalogEntriesCompanion toCompanion(bool nullToAbsent) {
    return MedicationCatalogEntriesCompanion(
      id: Value(id),
      sourceName: Value(sourceName),
      sourcePriority: Value(sourcePriority),
      sourceRecordId: Value(sourceRecordId),
      canonicalCode: Value(canonicalCode),
      displayName: Value(displayName),
      activeSubstance: activeSubstance == null && nullToAbsent
          ? const Value.absent()
          : Value(activeSubstance),
      strength: strength == null && nullToAbsent
          ? const Value.absent()
          : Value(strength),
      pharmaceuticalForm: pharmaceuticalForm == null && nullToAbsent
          ? const Value.absent()
          : Value(pharmaceuticalForm),
      presentation: presentation == null && nullToAbsent
          ? const Value.absent()
          : Value(presentation),
      holder: holder == null && nullToAbsent
          ? const Value.absent()
          : Value(holder),
      leafletUrl: leafletUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(leafletUrl),
      rcmUrl: rcmUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(rcmUrl),
      sourceUrl: sourceUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceUrl),
      imageUrl: imageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(imageUrl),
      updatedAt: Value(updatedAt),
    );
  }

  factory MedicationCatalogEntryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MedicationCatalogEntryRow(
      id: serializer.fromJson<String>(json['id']),
      sourceName: serializer.fromJson<String>(json['sourceName']),
      sourcePriority: serializer.fromJson<int>(json['sourcePriority']),
      sourceRecordId: serializer.fromJson<String>(json['sourceRecordId']),
      canonicalCode: serializer.fromJson<String>(json['canonicalCode']),
      displayName: serializer.fromJson<String>(json['displayName']),
      activeSubstance: serializer.fromJson<String?>(json['activeSubstance']),
      strength: serializer.fromJson<String?>(json['strength']),
      pharmaceuticalForm: serializer.fromJson<String?>(
        json['pharmaceuticalForm'],
      ),
      presentation: serializer.fromJson<String?>(json['presentation']),
      holder: serializer.fromJson<String?>(json['holder']),
      leafletUrl: serializer.fromJson<String?>(json['leafletUrl']),
      rcmUrl: serializer.fromJson<String?>(json['rcmUrl']),
      sourceUrl: serializer.fromJson<String?>(json['sourceUrl']),
      imageUrl: serializer.fromJson<String?>(json['imageUrl']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sourceName': serializer.toJson<String>(sourceName),
      'sourcePriority': serializer.toJson<int>(sourcePriority),
      'sourceRecordId': serializer.toJson<String>(sourceRecordId),
      'canonicalCode': serializer.toJson<String>(canonicalCode),
      'displayName': serializer.toJson<String>(displayName),
      'activeSubstance': serializer.toJson<String?>(activeSubstance),
      'strength': serializer.toJson<String?>(strength),
      'pharmaceuticalForm': serializer.toJson<String?>(pharmaceuticalForm),
      'presentation': serializer.toJson<String?>(presentation),
      'holder': serializer.toJson<String?>(holder),
      'leafletUrl': serializer.toJson<String?>(leafletUrl),
      'rcmUrl': serializer.toJson<String?>(rcmUrl),
      'sourceUrl': serializer.toJson<String?>(sourceUrl),
      'imageUrl': serializer.toJson<String?>(imageUrl),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  MedicationCatalogEntryRow copyWith({
    String? id,
    String? sourceName,
    int? sourcePriority,
    String? sourceRecordId,
    String? canonicalCode,
    String? displayName,
    Value<String?> activeSubstance = const Value.absent(),
    Value<String?> strength = const Value.absent(),
    Value<String?> pharmaceuticalForm = const Value.absent(),
    Value<String?> presentation = const Value.absent(),
    Value<String?> holder = const Value.absent(),
    Value<String?> leafletUrl = const Value.absent(),
    Value<String?> rcmUrl = const Value.absent(),
    Value<String?> sourceUrl = const Value.absent(),
    Value<String?> imageUrl = const Value.absent(),
    DateTime? updatedAt,
  }) => MedicationCatalogEntryRow(
    id: id ?? this.id,
    sourceName: sourceName ?? this.sourceName,
    sourcePriority: sourcePriority ?? this.sourcePriority,
    sourceRecordId: sourceRecordId ?? this.sourceRecordId,
    canonicalCode: canonicalCode ?? this.canonicalCode,
    displayName: displayName ?? this.displayName,
    activeSubstance: activeSubstance.present
        ? activeSubstance.value
        : this.activeSubstance,
    strength: strength.present ? strength.value : this.strength,
    pharmaceuticalForm: pharmaceuticalForm.present
        ? pharmaceuticalForm.value
        : this.pharmaceuticalForm,
    presentation: presentation.present ? presentation.value : this.presentation,
    holder: holder.present ? holder.value : this.holder,
    leafletUrl: leafletUrl.present ? leafletUrl.value : this.leafletUrl,
    rcmUrl: rcmUrl.present ? rcmUrl.value : this.rcmUrl,
    sourceUrl: sourceUrl.present ? sourceUrl.value : this.sourceUrl,
    imageUrl: imageUrl.present ? imageUrl.value : this.imageUrl,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  MedicationCatalogEntryRow copyWithCompanion(
    MedicationCatalogEntriesCompanion data,
  ) {
    return MedicationCatalogEntryRow(
      id: data.id.present ? data.id.value : this.id,
      sourceName: data.sourceName.present
          ? data.sourceName.value
          : this.sourceName,
      sourcePriority: data.sourcePriority.present
          ? data.sourcePriority.value
          : this.sourcePriority,
      sourceRecordId: data.sourceRecordId.present
          ? data.sourceRecordId.value
          : this.sourceRecordId,
      canonicalCode: data.canonicalCode.present
          ? data.canonicalCode.value
          : this.canonicalCode,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      activeSubstance: data.activeSubstance.present
          ? data.activeSubstance.value
          : this.activeSubstance,
      strength: data.strength.present ? data.strength.value : this.strength,
      pharmaceuticalForm: data.pharmaceuticalForm.present
          ? data.pharmaceuticalForm.value
          : this.pharmaceuticalForm,
      presentation: data.presentation.present
          ? data.presentation.value
          : this.presentation,
      holder: data.holder.present ? data.holder.value : this.holder,
      leafletUrl: data.leafletUrl.present
          ? data.leafletUrl.value
          : this.leafletUrl,
      rcmUrl: data.rcmUrl.present ? data.rcmUrl.value : this.rcmUrl,
      sourceUrl: data.sourceUrl.present ? data.sourceUrl.value : this.sourceUrl,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MedicationCatalogEntryRow(')
          ..write('id: $id, ')
          ..write('sourceName: $sourceName, ')
          ..write('sourcePriority: $sourcePriority, ')
          ..write('sourceRecordId: $sourceRecordId, ')
          ..write('canonicalCode: $canonicalCode, ')
          ..write('displayName: $displayName, ')
          ..write('activeSubstance: $activeSubstance, ')
          ..write('strength: $strength, ')
          ..write('pharmaceuticalForm: $pharmaceuticalForm, ')
          ..write('presentation: $presentation, ')
          ..write('holder: $holder, ')
          ..write('leafletUrl: $leafletUrl, ')
          ..write('rcmUrl: $rcmUrl, ')
          ..write('sourceUrl: $sourceUrl, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sourceName,
    sourcePriority,
    sourceRecordId,
    canonicalCode,
    displayName,
    activeSubstance,
    strength,
    pharmaceuticalForm,
    presentation,
    holder,
    leafletUrl,
    rcmUrl,
    sourceUrl,
    imageUrl,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MedicationCatalogEntryRow &&
          other.id == this.id &&
          other.sourceName == this.sourceName &&
          other.sourcePriority == this.sourcePriority &&
          other.sourceRecordId == this.sourceRecordId &&
          other.canonicalCode == this.canonicalCode &&
          other.displayName == this.displayName &&
          other.activeSubstance == this.activeSubstance &&
          other.strength == this.strength &&
          other.pharmaceuticalForm == this.pharmaceuticalForm &&
          other.presentation == this.presentation &&
          other.holder == this.holder &&
          other.leafletUrl == this.leafletUrl &&
          other.rcmUrl == this.rcmUrl &&
          other.sourceUrl == this.sourceUrl &&
          other.imageUrl == this.imageUrl &&
          other.updatedAt == this.updatedAt);
}

class MedicationCatalogEntriesCompanion
    extends UpdateCompanion<MedicationCatalogEntryRow> {
  final Value<String> id;
  final Value<String> sourceName;
  final Value<int> sourcePriority;
  final Value<String> sourceRecordId;
  final Value<String> canonicalCode;
  final Value<String> displayName;
  final Value<String?> activeSubstance;
  final Value<String?> strength;
  final Value<String?> pharmaceuticalForm;
  final Value<String?> presentation;
  final Value<String?> holder;
  final Value<String?> leafletUrl;
  final Value<String?> rcmUrl;
  final Value<String?> sourceUrl;
  final Value<String?> imageUrl;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const MedicationCatalogEntriesCompanion({
    this.id = const Value.absent(),
    this.sourceName = const Value.absent(),
    this.sourcePriority = const Value.absent(),
    this.sourceRecordId = const Value.absent(),
    this.canonicalCode = const Value.absent(),
    this.displayName = const Value.absent(),
    this.activeSubstance = const Value.absent(),
    this.strength = const Value.absent(),
    this.pharmaceuticalForm = const Value.absent(),
    this.presentation = const Value.absent(),
    this.holder = const Value.absent(),
    this.leafletUrl = const Value.absent(),
    this.rcmUrl = const Value.absent(),
    this.sourceUrl = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MedicationCatalogEntriesCompanion.insert({
    required String id,
    required String sourceName,
    required int sourcePriority,
    required String sourceRecordId,
    required String canonicalCode,
    required String displayName,
    this.activeSubstance = const Value.absent(),
    this.strength = const Value.absent(),
    this.pharmaceuticalForm = const Value.absent(),
    this.presentation = const Value.absent(),
    this.holder = const Value.absent(),
    this.leafletUrl = const Value.absent(),
    this.rcmUrl = const Value.absent(),
    this.sourceUrl = const Value.absent(),
    this.imageUrl = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sourceName = Value(sourceName),
       sourcePriority = Value(sourcePriority),
       sourceRecordId = Value(sourceRecordId),
       canonicalCode = Value(canonicalCode),
       displayName = Value(displayName),
       updatedAt = Value(updatedAt);
  static Insertable<MedicationCatalogEntryRow> custom({
    Expression<String>? id,
    Expression<String>? sourceName,
    Expression<int>? sourcePriority,
    Expression<String>? sourceRecordId,
    Expression<String>? canonicalCode,
    Expression<String>? displayName,
    Expression<String>? activeSubstance,
    Expression<String>? strength,
    Expression<String>? pharmaceuticalForm,
    Expression<String>? presentation,
    Expression<String>? holder,
    Expression<String>? leafletUrl,
    Expression<String>? rcmUrl,
    Expression<String>? sourceUrl,
    Expression<String>? imageUrl,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sourceName != null) 'source_name': sourceName,
      if (sourcePriority != null) 'source_priority': sourcePriority,
      if (sourceRecordId != null) 'source_record_id': sourceRecordId,
      if (canonicalCode != null) 'canonical_code': canonicalCode,
      if (displayName != null) 'display_name': displayName,
      if (activeSubstance != null) 'active_substance': activeSubstance,
      if (strength != null) 'strength': strength,
      if (pharmaceuticalForm != null) 'pharmaceutical_form': pharmaceuticalForm,
      if (presentation != null) 'presentation': presentation,
      if (holder != null) 'holder': holder,
      if (leafletUrl != null) 'leaflet_url': leafletUrl,
      if (rcmUrl != null) 'rcm_url': rcmUrl,
      if (sourceUrl != null) 'source_url': sourceUrl,
      if (imageUrl != null) 'image_url': imageUrl,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MedicationCatalogEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? sourceName,
    Value<int>? sourcePriority,
    Value<String>? sourceRecordId,
    Value<String>? canonicalCode,
    Value<String>? displayName,
    Value<String?>? activeSubstance,
    Value<String?>? strength,
    Value<String?>? pharmaceuticalForm,
    Value<String?>? presentation,
    Value<String?>? holder,
    Value<String?>? leafletUrl,
    Value<String?>? rcmUrl,
    Value<String?>? sourceUrl,
    Value<String?>? imageUrl,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return MedicationCatalogEntriesCompanion(
      id: id ?? this.id,
      sourceName: sourceName ?? this.sourceName,
      sourcePriority: sourcePriority ?? this.sourcePriority,
      sourceRecordId: sourceRecordId ?? this.sourceRecordId,
      canonicalCode: canonicalCode ?? this.canonicalCode,
      displayName: displayName ?? this.displayName,
      activeSubstance: activeSubstance ?? this.activeSubstance,
      strength: strength ?? this.strength,
      pharmaceuticalForm: pharmaceuticalForm ?? this.pharmaceuticalForm,
      presentation: presentation ?? this.presentation,
      holder: holder ?? this.holder,
      leafletUrl: leafletUrl ?? this.leafletUrl,
      rcmUrl: rcmUrl ?? this.rcmUrl,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sourceName.present) {
      map['source_name'] = Variable<String>(sourceName.value);
    }
    if (sourcePriority.present) {
      map['source_priority'] = Variable<int>(sourcePriority.value);
    }
    if (sourceRecordId.present) {
      map['source_record_id'] = Variable<String>(sourceRecordId.value);
    }
    if (canonicalCode.present) {
      map['canonical_code'] = Variable<String>(canonicalCode.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (activeSubstance.present) {
      map['active_substance'] = Variable<String>(activeSubstance.value);
    }
    if (strength.present) {
      map['strength'] = Variable<String>(strength.value);
    }
    if (pharmaceuticalForm.present) {
      map['pharmaceutical_form'] = Variable<String>(pharmaceuticalForm.value);
    }
    if (presentation.present) {
      map['presentation'] = Variable<String>(presentation.value);
    }
    if (holder.present) {
      map['holder'] = Variable<String>(holder.value);
    }
    if (leafletUrl.present) {
      map['leaflet_url'] = Variable<String>(leafletUrl.value);
    }
    if (rcmUrl.present) {
      map['rcm_url'] = Variable<String>(rcmUrl.value);
    }
    if (sourceUrl.present) {
      map['source_url'] = Variable<String>(sourceUrl.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MedicationCatalogEntriesCompanion(')
          ..write('id: $id, ')
          ..write('sourceName: $sourceName, ')
          ..write('sourcePriority: $sourcePriority, ')
          ..write('sourceRecordId: $sourceRecordId, ')
          ..write('canonicalCode: $canonicalCode, ')
          ..write('displayName: $displayName, ')
          ..write('activeSubstance: $activeSubstance, ')
          ..write('strength: $strength, ')
          ..write('pharmaceuticalForm: $pharmaceuticalForm, ')
          ..write('presentation: $presentation, ')
          ..write('holder: $holder, ')
          ..write('leafletUrl: $leafletUrl, ')
          ..write('rcmUrl: $rcmUrl, ')
          ..write('sourceUrl: $sourceUrl, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MedicationLookupCodesTable extends MedicationLookupCodes
    with TableInfo<$MedicationLookupCodesTable, MedicationLookupCodeRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MedicationLookupCodesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _medicationIdMeta = const VerificationMeta(
    'medicationId',
  );
  @override
  late final GeneratedColumn<String> medicationId = GeneratedColumn<String>(
    'medication_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES medication_catalog_entries (id)',
    ),
  );
  static const VerificationMeta _normalizedCodeMeta = const VerificationMeta(
    'normalizedCode',
  );
  @override
  late final GeneratedColumn<String> normalizedCode = GeneratedColumn<String>(
    'normalized_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _codeKindMeta = const VerificationMeta(
    'codeKind',
  );
  @override
  late final GeneratedColumn<String> codeKind = GeneratedColumn<String>(
    'code_kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isPrimaryMeta = const VerificationMeta(
    'isPrimary',
  );
  @override
  late final GeneratedColumn<bool> isPrimary = GeneratedColumn<bool>(
    'is_primary',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_primary" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    medicationId,
    normalizedCode,
    codeKind,
    isPrimary,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'medication_lookup_codes';
  @override
  VerificationContext validateIntegrity(
    Insertable<MedicationLookupCodeRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('medication_id')) {
      context.handle(
        _medicationIdMeta,
        medicationId.isAcceptableOrUnknown(
          data['medication_id']!,
          _medicationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_medicationIdMeta);
    }
    if (data.containsKey('normalized_code')) {
      context.handle(
        _normalizedCodeMeta,
        normalizedCode.isAcceptableOrUnknown(
          data['normalized_code']!,
          _normalizedCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_normalizedCodeMeta);
    }
    if (data.containsKey('code_kind')) {
      context.handle(
        _codeKindMeta,
        codeKind.isAcceptableOrUnknown(data['code_kind']!, _codeKindMeta),
      );
    } else if (isInserting) {
      context.missing(_codeKindMeta);
    }
    if (data.containsKey('is_primary')) {
      context.handle(
        _isPrimaryMeta,
        isPrimary.isAcceptableOrUnknown(data['is_primary']!, _isPrimaryMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MedicationLookupCodeRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MedicationLookupCodeRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      medicationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}medication_id'],
      )!,
      normalizedCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}normalized_code'],
      )!,
      codeKind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code_kind'],
      )!,
      isPrimary: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_primary'],
      )!,
    );
  }

  @override
  $MedicationLookupCodesTable createAlias(String alias) {
    return $MedicationLookupCodesTable(attachedDatabase, alias);
  }
}

class MedicationLookupCodeRow extends DataClass
    implements Insertable<MedicationLookupCodeRow> {
  final String id;
  final String medicationId;
  final String normalizedCode;
  final String codeKind;
  final bool isPrimary;
  const MedicationLookupCodeRow({
    required this.id,
    required this.medicationId,
    required this.normalizedCode,
    required this.codeKind,
    required this.isPrimary,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['medication_id'] = Variable<String>(medicationId);
    map['normalized_code'] = Variable<String>(normalizedCode);
    map['code_kind'] = Variable<String>(codeKind);
    map['is_primary'] = Variable<bool>(isPrimary);
    return map;
  }

  MedicationLookupCodesCompanion toCompanion(bool nullToAbsent) {
    return MedicationLookupCodesCompanion(
      id: Value(id),
      medicationId: Value(medicationId),
      normalizedCode: Value(normalizedCode),
      codeKind: Value(codeKind),
      isPrimary: Value(isPrimary),
    );
  }

  factory MedicationLookupCodeRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MedicationLookupCodeRow(
      id: serializer.fromJson<String>(json['id']),
      medicationId: serializer.fromJson<String>(json['medicationId']),
      normalizedCode: serializer.fromJson<String>(json['normalizedCode']),
      codeKind: serializer.fromJson<String>(json['codeKind']),
      isPrimary: serializer.fromJson<bool>(json['isPrimary']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'medicationId': serializer.toJson<String>(medicationId),
      'normalizedCode': serializer.toJson<String>(normalizedCode),
      'codeKind': serializer.toJson<String>(codeKind),
      'isPrimary': serializer.toJson<bool>(isPrimary),
    };
  }

  MedicationLookupCodeRow copyWith({
    String? id,
    String? medicationId,
    String? normalizedCode,
    String? codeKind,
    bool? isPrimary,
  }) => MedicationLookupCodeRow(
    id: id ?? this.id,
    medicationId: medicationId ?? this.medicationId,
    normalizedCode: normalizedCode ?? this.normalizedCode,
    codeKind: codeKind ?? this.codeKind,
    isPrimary: isPrimary ?? this.isPrimary,
  );
  MedicationLookupCodeRow copyWithCompanion(
    MedicationLookupCodesCompanion data,
  ) {
    return MedicationLookupCodeRow(
      id: data.id.present ? data.id.value : this.id,
      medicationId: data.medicationId.present
          ? data.medicationId.value
          : this.medicationId,
      normalizedCode: data.normalizedCode.present
          ? data.normalizedCode.value
          : this.normalizedCode,
      codeKind: data.codeKind.present ? data.codeKind.value : this.codeKind,
      isPrimary: data.isPrimary.present ? data.isPrimary.value : this.isPrimary,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MedicationLookupCodeRow(')
          ..write('id: $id, ')
          ..write('medicationId: $medicationId, ')
          ..write('normalizedCode: $normalizedCode, ')
          ..write('codeKind: $codeKind, ')
          ..write('isPrimary: $isPrimary')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, medicationId, normalizedCode, codeKind, isPrimary);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MedicationLookupCodeRow &&
          other.id == this.id &&
          other.medicationId == this.medicationId &&
          other.normalizedCode == this.normalizedCode &&
          other.codeKind == this.codeKind &&
          other.isPrimary == this.isPrimary);
}

class MedicationLookupCodesCompanion
    extends UpdateCompanion<MedicationLookupCodeRow> {
  final Value<String> id;
  final Value<String> medicationId;
  final Value<String> normalizedCode;
  final Value<String> codeKind;
  final Value<bool> isPrimary;
  final Value<int> rowid;
  const MedicationLookupCodesCompanion({
    this.id = const Value.absent(),
    this.medicationId = const Value.absent(),
    this.normalizedCode = const Value.absent(),
    this.codeKind = const Value.absent(),
    this.isPrimary = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MedicationLookupCodesCompanion.insert({
    required String id,
    required String medicationId,
    required String normalizedCode,
    required String codeKind,
    this.isPrimary = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       medicationId = Value(medicationId),
       normalizedCode = Value(normalizedCode),
       codeKind = Value(codeKind);
  static Insertable<MedicationLookupCodeRow> custom({
    Expression<String>? id,
    Expression<String>? medicationId,
    Expression<String>? normalizedCode,
    Expression<String>? codeKind,
    Expression<bool>? isPrimary,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (medicationId != null) 'medication_id': medicationId,
      if (normalizedCode != null) 'normalized_code': normalizedCode,
      if (codeKind != null) 'code_kind': codeKind,
      if (isPrimary != null) 'is_primary': isPrimary,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MedicationLookupCodesCompanion copyWith({
    Value<String>? id,
    Value<String>? medicationId,
    Value<String>? normalizedCode,
    Value<String>? codeKind,
    Value<bool>? isPrimary,
    Value<int>? rowid,
  }) {
    return MedicationLookupCodesCompanion(
      id: id ?? this.id,
      medicationId: medicationId ?? this.medicationId,
      normalizedCode: normalizedCode ?? this.normalizedCode,
      codeKind: codeKind ?? this.codeKind,
      isPrimary: isPrimary ?? this.isPrimary,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (medicationId.present) {
      map['medication_id'] = Variable<String>(medicationId.value);
    }
    if (normalizedCode.present) {
      map['normalized_code'] = Variable<String>(normalizedCode.value);
    }
    if (codeKind.present) {
      map['code_kind'] = Variable<String>(codeKind.value);
    }
    if (isPrimary.present) {
      map['is_primary'] = Variable<bool>(isPrimary.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MedicationLookupCodesCompanion(')
          ..write('id: $id, ')
          ..write('medicationId: $medicationId, ')
          ..write('normalizedCode: $normalizedCode, ')
          ..write('codeKind: $codeKind, ')
          ..write('isPrimary: $isPrimary, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MedicationEnrichmentStatusesTable extends MedicationEnrichmentStatuses
    with
        TableInfo<
          $MedicationEnrichmentStatusesTable,
          MedicationEnrichmentStatusRow
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MedicationEnrichmentStatusesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _normalizedCodeMeta = const VerificationMeta(
    'normalizedCode',
  );
  @override
  late final GeneratedColumn<String> normalizedCode = GeneratedColumn<String>(
    'normalized_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _codeKindMeta = const VerificationMeta(
    'codeKind',
  );
  @override
  late final GeneratedColumn<String> codeKind = GeneratedColumn<String>(
    'code_kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastAttemptedAtMeta = const VerificationMeta(
    'lastAttemptedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastAttemptedAt =
      GeneratedColumn<DateTime>(
        'last_attempted_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastSucceededAtMeta = const VerificationMeta(
    'lastSucceededAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSucceededAt =
      GeneratedColumn<DateTime>(
        'last_succeeded_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastFailedAtMeta = const VerificationMeta(
    'lastFailedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastFailedAt = GeneratedColumn<DateTime>(
    'last_failed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _attemptCountMeta = const VerificationMeta(
    'attemptCount',
  );
  @override
  late final GeneratedColumn<int> attemptCount = GeneratedColumn<int>(
    'attempt_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _nextRetryAtMeta = const VerificationMeta(
    'nextRetryAt',
  );
  @override
  late final GeneratedColumn<DateTime> nextRetryAt = GeneratedColumn<DateTime>(
    'next_retry_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastProviderNameMeta = const VerificationMeta(
    'lastProviderName',
  );
  @override
  late final GeneratedColumn<String> lastProviderName = GeneratedColumn<String>(
    'last_provider_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    normalizedCode,
    codeKind,
    lastAttemptedAt,
    lastSucceededAt,
    lastFailedAt,
    attemptCount,
    nextRetryAt,
    lastError,
    lastProviderName,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'medication_enrichment_status';
  @override
  VerificationContext validateIntegrity(
    Insertable<MedicationEnrichmentStatusRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('normalized_code')) {
      context.handle(
        _normalizedCodeMeta,
        normalizedCode.isAcceptableOrUnknown(
          data['normalized_code']!,
          _normalizedCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_normalizedCodeMeta);
    }
    if (data.containsKey('code_kind')) {
      context.handle(
        _codeKindMeta,
        codeKind.isAcceptableOrUnknown(data['code_kind']!, _codeKindMeta),
      );
    } else if (isInserting) {
      context.missing(_codeKindMeta);
    }
    if (data.containsKey('last_attempted_at')) {
      context.handle(
        _lastAttemptedAtMeta,
        lastAttemptedAt.isAcceptableOrUnknown(
          data['last_attempted_at']!,
          _lastAttemptedAtMeta,
        ),
      );
    }
    if (data.containsKey('last_succeeded_at')) {
      context.handle(
        _lastSucceededAtMeta,
        lastSucceededAt.isAcceptableOrUnknown(
          data['last_succeeded_at']!,
          _lastSucceededAtMeta,
        ),
      );
    }
    if (data.containsKey('last_failed_at')) {
      context.handle(
        _lastFailedAtMeta,
        lastFailedAt.isAcceptableOrUnknown(
          data['last_failed_at']!,
          _lastFailedAtMeta,
        ),
      );
    }
    if (data.containsKey('attempt_count')) {
      context.handle(
        _attemptCountMeta,
        attemptCount.isAcceptableOrUnknown(
          data['attempt_count']!,
          _attemptCountMeta,
        ),
      );
    }
    if (data.containsKey('next_retry_at')) {
      context.handle(
        _nextRetryAtMeta,
        nextRetryAt.isAcceptableOrUnknown(
          data['next_retry_at']!,
          _nextRetryAtMeta,
        ),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('last_provider_name')) {
      context.handle(
        _lastProviderNameMeta,
        lastProviderName.isAcceptableOrUnknown(
          data['last_provider_name']!,
          _lastProviderNameMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MedicationEnrichmentStatusRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MedicationEnrichmentStatusRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      normalizedCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}normalized_code'],
      )!,
      codeKind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code_kind'],
      )!,
      lastAttemptedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_attempted_at'],
      ),
      lastSucceededAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_succeeded_at'],
      ),
      lastFailedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_failed_at'],
      ),
      attemptCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempt_count'],
      )!,
      nextRetryAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_retry_at'],
      ),
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      lastProviderName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_provider_name'],
      ),
    );
  }

  @override
  $MedicationEnrichmentStatusesTable createAlias(String alias) {
    return $MedicationEnrichmentStatusesTable(attachedDatabase, alias);
  }
}

class MedicationEnrichmentStatusRow extends DataClass
    implements Insertable<MedicationEnrichmentStatusRow> {
  final String id;
  final String normalizedCode;
  final String codeKind;
  final DateTime? lastAttemptedAt;
  final DateTime? lastSucceededAt;
  final DateTime? lastFailedAt;
  final int attemptCount;
  final DateTime? nextRetryAt;
  final String? lastError;
  final String? lastProviderName;
  const MedicationEnrichmentStatusRow({
    required this.id,
    required this.normalizedCode,
    required this.codeKind,
    this.lastAttemptedAt,
    this.lastSucceededAt,
    this.lastFailedAt,
    required this.attemptCount,
    this.nextRetryAt,
    this.lastError,
    this.lastProviderName,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['normalized_code'] = Variable<String>(normalizedCode);
    map['code_kind'] = Variable<String>(codeKind);
    if (!nullToAbsent || lastAttemptedAt != null) {
      map['last_attempted_at'] = Variable<DateTime>(lastAttemptedAt);
    }
    if (!nullToAbsent || lastSucceededAt != null) {
      map['last_succeeded_at'] = Variable<DateTime>(lastSucceededAt);
    }
    if (!nullToAbsent || lastFailedAt != null) {
      map['last_failed_at'] = Variable<DateTime>(lastFailedAt);
    }
    map['attempt_count'] = Variable<int>(attemptCount);
    if (!nullToAbsent || nextRetryAt != null) {
      map['next_retry_at'] = Variable<DateTime>(nextRetryAt);
    }
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    if (!nullToAbsent || lastProviderName != null) {
      map['last_provider_name'] = Variable<String>(lastProviderName);
    }
    return map;
  }

  MedicationEnrichmentStatusesCompanion toCompanion(bool nullToAbsent) {
    return MedicationEnrichmentStatusesCompanion(
      id: Value(id),
      normalizedCode: Value(normalizedCode),
      codeKind: Value(codeKind),
      lastAttemptedAt: lastAttemptedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAttemptedAt),
      lastSucceededAt: lastSucceededAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSucceededAt),
      lastFailedAt: lastFailedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastFailedAt),
      attemptCount: Value(attemptCount),
      nextRetryAt: nextRetryAt == null && nullToAbsent
          ? const Value.absent()
          : Value(nextRetryAt),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      lastProviderName: lastProviderName == null && nullToAbsent
          ? const Value.absent()
          : Value(lastProviderName),
    );
  }

  factory MedicationEnrichmentStatusRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MedicationEnrichmentStatusRow(
      id: serializer.fromJson<String>(json['id']),
      normalizedCode: serializer.fromJson<String>(json['normalizedCode']),
      codeKind: serializer.fromJson<String>(json['codeKind']),
      lastAttemptedAt: serializer.fromJson<DateTime?>(json['lastAttemptedAt']),
      lastSucceededAt: serializer.fromJson<DateTime?>(json['lastSucceededAt']),
      lastFailedAt: serializer.fromJson<DateTime?>(json['lastFailedAt']),
      attemptCount: serializer.fromJson<int>(json['attemptCount']),
      nextRetryAt: serializer.fromJson<DateTime?>(json['nextRetryAt']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      lastProviderName: serializer.fromJson<String?>(json['lastProviderName']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'normalizedCode': serializer.toJson<String>(normalizedCode),
      'codeKind': serializer.toJson<String>(codeKind),
      'lastAttemptedAt': serializer.toJson<DateTime?>(lastAttemptedAt),
      'lastSucceededAt': serializer.toJson<DateTime?>(lastSucceededAt),
      'lastFailedAt': serializer.toJson<DateTime?>(lastFailedAt),
      'attemptCount': serializer.toJson<int>(attemptCount),
      'nextRetryAt': serializer.toJson<DateTime?>(nextRetryAt),
      'lastError': serializer.toJson<String?>(lastError),
      'lastProviderName': serializer.toJson<String?>(lastProviderName),
    };
  }

  MedicationEnrichmentStatusRow copyWith({
    String? id,
    String? normalizedCode,
    String? codeKind,
    Value<DateTime?> lastAttemptedAt = const Value.absent(),
    Value<DateTime?> lastSucceededAt = const Value.absent(),
    Value<DateTime?> lastFailedAt = const Value.absent(),
    int? attemptCount,
    Value<DateTime?> nextRetryAt = const Value.absent(),
    Value<String?> lastError = const Value.absent(),
    Value<String?> lastProviderName = const Value.absent(),
  }) => MedicationEnrichmentStatusRow(
    id: id ?? this.id,
    normalizedCode: normalizedCode ?? this.normalizedCode,
    codeKind: codeKind ?? this.codeKind,
    lastAttemptedAt: lastAttemptedAt.present
        ? lastAttemptedAt.value
        : this.lastAttemptedAt,
    lastSucceededAt: lastSucceededAt.present
        ? lastSucceededAt.value
        : this.lastSucceededAt,
    lastFailedAt: lastFailedAt.present ? lastFailedAt.value : this.lastFailedAt,
    attemptCount: attemptCount ?? this.attemptCount,
    nextRetryAt: nextRetryAt.present ? nextRetryAt.value : this.nextRetryAt,
    lastError: lastError.present ? lastError.value : this.lastError,
    lastProviderName: lastProviderName.present
        ? lastProviderName.value
        : this.lastProviderName,
  );
  MedicationEnrichmentStatusRow copyWithCompanion(
    MedicationEnrichmentStatusesCompanion data,
  ) {
    return MedicationEnrichmentStatusRow(
      id: data.id.present ? data.id.value : this.id,
      normalizedCode: data.normalizedCode.present
          ? data.normalizedCode.value
          : this.normalizedCode,
      codeKind: data.codeKind.present ? data.codeKind.value : this.codeKind,
      lastAttemptedAt: data.lastAttemptedAt.present
          ? data.lastAttemptedAt.value
          : this.lastAttemptedAt,
      lastSucceededAt: data.lastSucceededAt.present
          ? data.lastSucceededAt.value
          : this.lastSucceededAt,
      lastFailedAt: data.lastFailedAt.present
          ? data.lastFailedAt.value
          : this.lastFailedAt,
      attemptCount: data.attemptCount.present
          ? data.attemptCount.value
          : this.attemptCount,
      nextRetryAt: data.nextRetryAt.present
          ? data.nextRetryAt.value
          : this.nextRetryAt,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      lastProviderName: data.lastProviderName.present
          ? data.lastProviderName.value
          : this.lastProviderName,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MedicationEnrichmentStatusRow(')
          ..write('id: $id, ')
          ..write('normalizedCode: $normalizedCode, ')
          ..write('codeKind: $codeKind, ')
          ..write('lastAttemptedAt: $lastAttemptedAt, ')
          ..write('lastSucceededAt: $lastSucceededAt, ')
          ..write('lastFailedAt: $lastFailedAt, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('nextRetryAt: $nextRetryAt, ')
          ..write('lastError: $lastError, ')
          ..write('lastProviderName: $lastProviderName')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    normalizedCode,
    codeKind,
    lastAttemptedAt,
    lastSucceededAt,
    lastFailedAt,
    attemptCount,
    nextRetryAt,
    lastError,
    lastProviderName,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MedicationEnrichmentStatusRow &&
          other.id == this.id &&
          other.normalizedCode == this.normalizedCode &&
          other.codeKind == this.codeKind &&
          other.lastAttemptedAt == this.lastAttemptedAt &&
          other.lastSucceededAt == this.lastSucceededAt &&
          other.lastFailedAt == this.lastFailedAt &&
          other.attemptCount == this.attemptCount &&
          other.nextRetryAt == this.nextRetryAt &&
          other.lastError == this.lastError &&
          other.lastProviderName == this.lastProviderName);
}

class MedicationEnrichmentStatusesCompanion
    extends UpdateCompanion<MedicationEnrichmentStatusRow> {
  final Value<String> id;
  final Value<String> normalizedCode;
  final Value<String> codeKind;
  final Value<DateTime?> lastAttemptedAt;
  final Value<DateTime?> lastSucceededAt;
  final Value<DateTime?> lastFailedAt;
  final Value<int> attemptCount;
  final Value<DateTime?> nextRetryAt;
  final Value<String?> lastError;
  final Value<String?> lastProviderName;
  final Value<int> rowid;
  const MedicationEnrichmentStatusesCompanion({
    this.id = const Value.absent(),
    this.normalizedCode = const Value.absent(),
    this.codeKind = const Value.absent(),
    this.lastAttemptedAt = const Value.absent(),
    this.lastSucceededAt = const Value.absent(),
    this.lastFailedAt = const Value.absent(),
    this.attemptCount = const Value.absent(),
    this.nextRetryAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.lastProviderName = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MedicationEnrichmentStatusesCompanion.insert({
    required String id,
    required String normalizedCode,
    required String codeKind,
    this.lastAttemptedAt = const Value.absent(),
    this.lastSucceededAt = const Value.absent(),
    this.lastFailedAt = const Value.absent(),
    this.attemptCount = const Value.absent(),
    this.nextRetryAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.lastProviderName = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       normalizedCode = Value(normalizedCode),
       codeKind = Value(codeKind);
  static Insertable<MedicationEnrichmentStatusRow> custom({
    Expression<String>? id,
    Expression<String>? normalizedCode,
    Expression<String>? codeKind,
    Expression<DateTime>? lastAttemptedAt,
    Expression<DateTime>? lastSucceededAt,
    Expression<DateTime>? lastFailedAt,
    Expression<int>? attemptCount,
    Expression<DateTime>? nextRetryAt,
    Expression<String>? lastError,
    Expression<String>? lastProviderName,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (normalizedCode != null) 'normalized_code': normalizedCode,
      if (codeKind != null) 'code_kind': codeKind,
      if (lastAttemptedAt != null) 'last_attempted_at': lastAttemptedAt,
      if (lastSucceededAt != null) 'last_succeeded_at': lastSucceededAt,
      if (lastFailedAt != null) 'last_failed_at': lastFailedAt,
      if (attemptCount != null) 'attempt_count': attemptCount,
      if (nextRetryAt != null) 'next_retry_at': nextRetryAt,
      if (lastError != null) 'last_error': lastError,
      if (lastProviderName != null) 'last_provider_name': lastProviderName,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MedicationEnrichmentStatusesCompanion copyWith({
    Value<String>? id,
    Value<String>? normalizedCode,
    Value<String>? codeKind,
    Value<DateTime?>? lastAttemptedAt,
    Value<DateTime?>? lastSucceededAt,
    Value<DateTime?>? lastFailedAt,
    Value<int>? attemptCount,
    Value<DateTime?>? nextRetryAt,
    Value<String?>? lastError,
    Value<String?>? lastProviderName,
    Value<int>? rowid,
  }) {
    return MedicationEnrichmentStatusesCompanion(
      id: id ?? this.id,
      normalizedCode: normalizedCode ?? this.normalizedCode,
      codeKind: codeKind ?? this.codeKind,
      lastAttemptedAt: lastAttemptedAt ?? this.lastAttemptedAt,
      lastSucceededAt: lastSucceededAt ?? this.lastSucceededAt,
      lastFailedAt: lastFailedAt ?? this.lastFailedAt,
      attemptCount: attemptCount ?? this.attemptCount,
      nextRetryAt: nextRetryAt ?? this.nextRetryAt,
      lastError: lastError ?? this.lastError,
      lastProviderName: lastProviderName ?? this.lastProviderName,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (normalizedCode.present) {
      map['normalized_code'] = Variable<String>(normalizedCode.value);
    }
    if (codeKind.present) {
      map['code_kind'] = Variable<String>(codeKind.value);
    }
    if (lastAttemptedAt.present) {
      map['last_attempted_at'] = Variable<DateTime>(lastAttemptedAt.value);
    }
    if (lastSucceededAt.present) {
      map['last_succeeded_at'] = Variable<DateTime>(lastSucceededAt.value);
    }
    if (lastFailedAt.present) {
      map['last_failed_at'] = Variable<DateTime>(lastFailedAt.value);
    }
    if (attemptCount.present) {
      map['attempt_count'] = Variable<int>(attemptCount.value);
    }
    if (nextRetryAt.present) {
      map['next_retry_at'] = Variable<DateTime>(nextRetryAt.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (lastProviderName.present) {
      map['last_provider_name'] = Variable<String>(lastProviderName.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MedicationEnrichmentStatusesCompanion(')
          ..write('id: $id, ')
          ..write('normalizedCode: $normalizedCode, ')
          ..write('codeKind: $codeKind, ')
          ..write('lastAttemptedAt: $lastAttemptedAt, ')
          ..write('lastSucceededAt: $lastSucceededAt, ')
          ..write('lastFailedAt: $lastFailedAt, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('nextRetryAt: $nextRetryAt, ')
          ..write('lastError: $lastError, ')
          ..write('lastProviderName: $lastProviderName, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MedicationCatalogStateTableTable extends MedicationCatalogStateTable
    with
        TableInfo<
          $MedicationCatalogStateTableTable,
          MedicationCatalogStateRow
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MedicationCatalogStateTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _csvLastImportedAtMeta = const VerificationMeta(
    'csvLastImportedAt',
  );
  @override
  late final GeneratedColumn<DateTime> csvLastImportedAt =
      GeneratedColumn<DateTime>(
        'csv_last_imported_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _csvEntryCountMeta = const VerificationMeta(
    'csvEntryCount',
  );
  @override
  late final GeneratedColumn<int> csvEntryCount = GeneratedColumn<int>(
    'csv_entry_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _csvSourceLabelMeta = const VerificationMeta(
    'csvSourceLabel',
  );
  @override
  late final GeneratedColumn<String> csvSourceLabel = GeneratedColumn<String>(
    'csv_source_label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    csvLastImportedAt,
    csvEntryCount,
    csvSourceLabel,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'medication_catalog_state';
  @override
  VerificationContext validateIntegrity(
    Insertable<MedicationCatalogStateRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('csv_last_imported_at')) {
      context.handle(
        _csvLastImportedAtMeta,
        csvLastImportedAt.isAcceptableOrUnknown(
          data['csv_last_imported_at']!,
          _csvLastImportedAtMeta,
        ),
      );
    }
    if (data.containsKey('csv_entry_count')) {
      context.handle(
        _csvEntryCountMeta,
        csvEntryCount.isAcceptableOrUnknown(
          data['csv_entry_count']!,
          _csvEntryCountMeta,
        ),
      );
    }
    if (data.containsKey('csv_source_label')) {
      context.handle(
        _csvSourceLabelMeta,
        csvSourceLabel.isAcceptableOrUnknown(
          data['csv_source_label']!,
          _csvSourceLabelMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MedicationCatalogStateRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MedicationCatalogStateRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      csvLastImportedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}csv_last_imported_at'],
      ),
      csvEntryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}csv_entry_count'],
      )!,
      csvSourceLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}csv_source_label'],
      ),
    );
  }

  @override
  $MedicationCatalogStateTableTable createAlias(String alias) {
    return $MedicationCatalogStateTableTable(attachedDatabase, alias);
  }
}

class MedicationCatalogStateRow extends DataClass
    implements Insertable<MedicationCatalogStateRow> {
  final String id;
  final DateTime? csvLastImportedAt;
  final int csvEntryCount;
  final String? csvSourceLabel;
  const MedicationCatalogStateRow({
    required this.id,
    this.csvLastImportedAt,
    required this.csvEntryCount,
    this.csvSourceLabel,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || csvLastImportedAt != null) {
      map['csv_last_imported_at'] = Variable<DateTime>(csvLastImportedAt);
    }
    map['csv_entry_count'] = Variable<int>(csvEntryCount);
    if (!nullToAbsent || csvSourceLabel != null) {
      map['csv_source_label'] = Variable<String>(csvSourceLabel);
    }
    return map;
  }

  MedicationCatalogStateTableCompanion toCompanion(bool nullToAbsent) {
    return MedicationCatalogStateTableCompanion(
      id: Value(id),
      csvLastImportedAt: csvLastImportedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(csvLastImportedAt),
      csvEntryCount: Value(csvEntryCount),
      csvSourceLabel: csvSourceLabel == null && nullToAbsent
          ? const Value.absent()
          : Value(csvSourceLabel),
    );
  }

  factory MedicationCatalogStateRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MedicationCatalogStateRow(
      id: serializer.fromJson<String>(json['id']),
      csvLastImportedAt: serializer.fromJson<DateTime?>(
        json['csvLastImportedAt'],
      ),
      csvEntryCount: serializer.fromJson<int>(json['csvEntryCount']),
      csvSourceLabel: serializer.fromJson<String?>(json['csvSourceLabel']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'csvLastImportedAt': serializer.toJson<DateTime?>(csvLastImportedAt),
      'csvEntryCount': serializer.toJson<int>(csvEntryCount),
      'csvSourceLabel': serializer.toJson<String?>(csvSourceLabel),
    };
  }

  MedicationCatalogStateRow copyWith({
    String? id,
    Value<DateTime?> csvLastImportedAt = const Value.absent(),
    int? csvEntryCount,
    Value<String?> csvSourceLabel = const Value.absent(),
  }) => MedicationCatalogStateRow(
    id: id ?? this.id,
    csvLastImportedAt: csvLastImportedAt.present
        ? csvLastImportedAt.value
        : this.csvLastImportedAt,
    csvEntryCount: csvEntryCount ?? this.csvEntryCount,
    csvSourceLabel: csvSourceLabel.present
        ? csvSourceLabel.value
        : this.csvSourceLabel,
  );
  MedicationCatalogStateRow copyWithCompanion(
    MedicationCatalogStateTableCompanion data,
  ) {
    return MedicationCatalogStateRow(
      id: data.id.present ? data.id.value : this.id,
      csvLastImportedAt: data.csvLastImportedAt.present
          ? data.csvLastImportedAt.value
          : this.csvLastImportedAt,
      csvEntryCount: data.csvEntryCount.present
          ? data.csvEntryCount.value
          : this.csvEntryCount,
      csvSourceLabel: data.csvSourceLabel.present
          ? data.csvSourceLabel.value
          : this.csvSourceLabel,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MedicationCatalogStateRow(')
          ..write('id: $id, ')
          ..write('csvLastImportedAt: $csvLastImportedAt, ')
          ..write('csvEntryCount: $csvEntryCount, ')
          ..write('csvSourceLabel: $csvSourceLabel')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, csvLastImportedAt, csvEntryCount, csvSourceLabel);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MedicationCatalogStateRow &&
          other.id == this.id &&
          other.csvLastImportedAt == this.csvLastImportedAt &&
          other.csvEntryCount == this.csvEntryCount &&
          other.csvSourceLabel == this.csvSourceLabel);
}

class MedicationCatalogStateTableCompanion
    extends UpdateCompanion<MedicationCatalogStateRow> {
  final Value<String> id;
  final Value<DateTime?> csvLastImportedAt;
  final Value<int> csvEntryCount;
  final Value<String?> csvSourceLabel;
  final Value<int> rowid;
  const MedicationCatalogStateTableCompanion({
    this.id = const Value.absent(),
    this.csvLastImportedAt = const Value.absent(),
    this.csvEntryCount = const Value.absent(),
    this.csvSourceLabel = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MedicationCatalogStateTableCompanion.insert({
    required String id,
    this.csvLastImportedAt = const Value.absent(),
    this.csvEntryCount = const Value.absent(),
    this.csvSourceLabel = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<MedicationCatalogStateRow> custom({
    Expression<String>? id,
    Expression<DateTime>? csvLastImportedAt,
    Expression<int>? csvEntryCount,
    Expression<String>? csvSourceLabel,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (csvLastImportedAt != null) 'csv_last_imported_at': csvLastImportedAt,
      if (csvEntryCount != null) 'csv_entry_count': csvEntryCount,
      if (csvSourceLabel != null) 'csv_source_label': csvSourceLabel,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MedicationCatalogStateTableCompanion copyWith({
    Value<String>? id,
    Value<DateTime?>? csvLastImportedAt,
    Value<int>? csvEntryCount,
    Value<String?>? csvSourceLabel,
    Value<int>? rowid,
  }) {
    return MedicationCatalogStateTableCompanion(
      id: id ?? this.id,
      csvLastImportedAt: csvLastImportedAt ?? this.csvLastImportedAt,
      csvEntryCount: csvEntryCount ?? this.csvEntryCount,
      csvSourceLabel: csvSourceLabel ?? this.csvSourceLabel,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (csvLastImportedAt.present) {
      map['csv_last_imported_at'] = Variable<DateTime>(csvLastImportedAt.value);
    }
    if (csvEntryCount.present) {
      map['csv_entry_count'] = Variable<int>(csvEntryCount.value);
    }
    if (csvSourceLabel.present) {
      map['csv_source_label'] = Variable<String>(csvSourceLabel.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MedicationCatalogStateTableCompanion(')
          ..write('id: $id, ')
          ..write('csvLastImportedAt: $csvLastImportedAt, ')
          ..write('csvEntryCount: $csvEntryCount, ')
          ..write('csvSourceLabel: $csvSourceLabel, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $InventorySessionsTable inventorySessions =
      $InventorySessionsTable(this);
  late final $ScanEventsTable scanEvents = $ScanEventsTable(this);
  late final $MedicationCatalogEntriesTable medicationCatalogEntries =
      $MedicationCatalogEntriesTable(this);
  late final $MedicationLookupCodesTable medicationLookupCodes =
      $MedicationLookupCodesTable(this);
  late final $MedicationEnrichmentStatusesTable medicationEnrichmentStatuses =
      $MedicationEnrichmentStatusesTable(this);
  late final $MedicationCatalogStateTableTable medicationCatalogStateTable =
      $MedicationCatalogStateTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    inventorySessions,
    scanEvents,
    medicationCatalogEntries,
    medicationLookupCodes,
    medicationEnrichmentStatuses,
    medicationCatalogStateTable,
  ];
}

typedef $$InventorySessionsTableCreateCompanionBuilder =
    InventorySessionsCompanion Function({
      required String id,
      required String name,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<bool> barcodeQuantityPromptEnabled,
      Value<int> rowid,
    });
typedef $$InventorySessionsTableUpdateCompanionBuilder =
    InventorySessionsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<bool> barcodeQuantityPromptEnabled,
      Value<int> rowid,
    });

final class $$InventorySessionsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $InventorySessionsTable,
          InventorySessionRow
        > {
  $$InventorySessionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$ScanEventsTable, List<ScanEventRow>>
  _scanEventsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.scanEvents,
    aliasName: $_aliasNameGenerator(
      db.inventorySessions.id,
      db.scanEvents.sessionId,
    ),
  );

  $$ScanEventsTableProcessedTableManager get scanEventsRefs {
    final manager = $$ScanEventsTableTableManager(
      $_db,
      $_db.scanEvents,
    ).filter((f) => f.sessionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_scanEventsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$InventorySessionsTableFilterComposer
    extends Composer<_$AppDatabase, $InventorySessionsTable> {
  $$InventorySessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get barcodeQuantityPromptEnabled => $composableBuilder(
    column: $table.barcodeQuantityPromptEnabled,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> scanEventsRefs(
    Expression<bool> Function($$ScanEventsTableFilterComposer f) f,
  ) {
    final $$ScanEventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.scanEvents,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScanEventsTableFilterComposer(
            $db: $db,
            $table: $db.scanEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$InventorySessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $InventorySessionsTable> {
  $$InventorySessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get barcodeQuantityPromptEnabled => $composableBuilder(
    column: $table.barcodeQuantityPromptEnabled,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$InventorySessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $InventorySessionsTable> {
  $$InventorySessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get barcodeQuantityPromptEnabled => $composableBuilder(
    column: $table.barcodeQuantityPromptEnabled,
    builder: (column) => column,
  );

  Expression<T> scanEventsRefs<T extends Object>(
    Expression<T> Function($$ScanEventsTableAnnotationComposer a) f,
  ) {
    final $$ScanEventsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.scanEvents,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScanEventsTableAnnotationComposer(
            $db: $db,
            $table: $db.scanEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$InventorySessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $InventorySessionsTable,
          InventorySessionRow,
          $$InventorySessionsTableFilterComposer,
          $$InventorySessionsTableOrderingComposer,
          $$InventorySessionsTableAnnotationComposer,
          $$InventorySessionsTableCreateCompanionBuilder,
          $$InventorySessionsTableUpdateCompanionBuilder,
          (InventorySessionRow, $$InventorySessionsTableReferences),
          InventorySessionRow,
          PrefetchHooks Function({bool scanEventsRefs})
        > {
  $$InventorySessionsTableTableManager(
    _$AppDatabase db,
    $InventorySessionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InventorySessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InventorySessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InventorySessionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> barcodeQuantityPromptEnabled = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InventorySessionsCompanion(
                id: id,
                name: name,
                createdAt: createdAt,
                updatedAt: updatedAt,
                barcodeQuantityPromptEnabled: barcodeQuantityPromptEnabled,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<bool> barcodeQuantityPromptEnabled = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InventorySessionsCompanion.insert(
                id: id,
                name: name,
                createdAt: createdAt,
                updatedAt: updatedAt,
                barcodeQuantityPromptEnabled: barcodeQuantityPromptEnabled,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$InventorySessionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({scanEventsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (scanEventsRefs) db.scanEvents],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (scanEventsRefs)
                    await $_getPrefetchedData<
                      InventorySessionRow,
                      $InventorySessionsTable,
                      ScanEventRow
                    >(
                      currentTable: table,
                      referencedTable: $$InventorySessionsTableReferences
                          ._scanEventsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$InventorySessionsTableReferences(
                            db,
                            table,
                            p0,
                          ).scanEventsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.sessionId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$InventorySessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $InventorySessionsTable,
      InventorySessionRow,
      $$InventorySessionsTableFilterComposer,
      $$InventorySessionsTableOrderingComposer,
      $$InventorySessionsTableAnnotationComposer,
      $$InventorySessionsTableCreateCompanionBuilder,
      $$InventorySessionsTableUpdateCompanionBuilder,
      (InventorySessionRow, $$InventorySessionsTableReferences),
      InventorySessionRow,
      PrefetchHooks Function({bool scanEventsRefs})
    >;
typedef $$ScanEventsTableCreateCompanionBuilder =
    ScanEventsCompanion Function({
      required String id,
      required String sessionId,
      required String productCode,
      required String codeType,
      required String raw,
      Value<String?> serialNumber,
      Value<String?> lot,
      Value<String?> expiry,
      required DateTime createdAt,
      Value<bool> isDeleted,
      Value<int> rowid,
    });
typedef $$ScanEventsTableUpdateCompanionBuilder =
    ScanEventsCompanion Function({
      Value<String> id,
      Value<String> sessionId,
      Value<String> productCode,
      Value<String> codeType,
      Value<String> raw,
      Value<String?> serialNumber,
      Value<String?> lot,
      Value<String?> expiry,
      Value<DateTime> createdAt,
      Value<bool> isDeleted,
      Value<int> rowid,
    });

final class $$ScanEventsTableReferences
    extends BaseReferences<_$AppDatabase, $ScanEventsTable, ScanEventRow> {
  $$ScanEventsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $InventorySessionsTable _sessionIdTable(_$AppDatabase db) =>
      db.inventorySessions.createAlias(
        $_aliasNameGenerator(db.scanEvents.sessionId, db.inventorySessions.id),
      );

  $$InventorySessionsTableProcessedTableManager get sessionId {
    final $_column = $_itemColumn<String>('session_id')!;

    final manager = $$InventorySessionsTableTableManager(
      $_db,
      $_db.inventorySessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ScanEventsTableFilterComposer
    extends Composer<_$AppDatabase, $ScanEventsTable> {
  $$ScanEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productCode => $composableBuilder(
    column: $table.productCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get codeType => $composableBuilder(
    column: $table.codeType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get raw => $composableBuilder(
    column: $table.raw,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serialNumber => $composableBuilder(
    column: $table.serialNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lot => $composableBuilder(
    column: $table.lot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get expiry => $composableBuilder(
    column: $table.expiry,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  $$InventorySessionsTableFilterComposer get sessionId {
    final $$InventorySessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.inventorySessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InventorySessionsTableFilterComposer(
            $db: $db,
            $table: $db.inventorySessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ScanEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $ScanEventsTable> {
  $$ScanEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productCode => $composableBuilder(
    column: $table.productCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get codeType => $composableBuilder(
    column: $table.codeType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get raw => $composableBuilder(
    column: $table.raw,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serialNumber => $composableBuilder(
    column: $table.serialNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lot => $composableBuilder(
    column: $table.lot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get expiry => $composableBuilder(
    column: $table.expiry,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  $$InventorySessionsTableOrderingComposer get sessionId {
    final $$InventorySessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.inventorySessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InventorySessionsTableOrderingComposer(
            $db: $db,
            $table: $db.inventorySessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ScanEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ScanEventsTable> {
  $$ScanEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get productCode => $composableBuilder(
    column: $table.productCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get codeType =>
      $composableBuilder(column: $table.codeType, builder: (column) => column);

  GeneratedColumn<String> get raw =>
      $composableBuilder(column: $table.raw, builder: (column) => column);

  GeneratedColumn<String> get serialNumber => $composableBuilder(
    column: $table.serialNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lot =>
      $composableBuilder(column: $table.lot, builder: (column) => column);

  GeneratedColumn<String> get expiry =>
      $composableBuilder(column: $table.expiry, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  $$InventorySessionsTableAnnotationComposer get sessionId {
    final $$InventorySessionsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.sessionId,
          referencedTable: $db.inventorySessions,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$InventorySessionsTableAnnotationComposer(
                $db: $db,
                $table: $db.inventorySessions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$ScanEventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ScanEventsTable,
          ScanEventRow,
          $$ScanEventsTableFilterComposer,
          $$ScanEventsTableOrderingComposer,
          $$ScanEventsTableAnnotationComposer,
          $$ScanEventsTableCreateCompanionBuilder,
          $$ScanEventsTableUpdateCompanionBuilder,
          (ScanEventRow, $$ScanEventsTableReferences),
          ScanEventRow,
          PrefetchHooks Function({bool sessionId})
        > {
  $$ScanEventsTableTableManager(_$AppDatabase db, $ScanEventsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ScanEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ScanEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ScanEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sessionId = const Value.absent(),
                Value<String> productCode = const Value.absent(),
                Value<String> codeType = const Value.absent(),
                Value<String> raw = const Value.absent(),
                Value<String?> serialNumber = const Value.absent(),
                Value<String?> lot = const Value.absent(),
                Value<String?> expiry = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ScanEventsCompanion(
                id: id,
                sessionId: sessionId,
                productCode: productCode,
                codeType: codeType,
                raw: raw,
                serialNumber: serialNumber,
                lot: lot,
                expiry: expiry,
                createdAt: createdAt,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sessionId,
                required String productCode,
                required String codeType,
                required String raw,
                Value<String?> serialNumber = const Value.absent(),
                Value<String?> lot = const Value.absent(),
                Value<String?> expiry = const Value.absent(),
                required DateTime createdAt,
                Value<bool> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ScanEventsCompanion.insert(
                id: id,
                sessionId: sessionId,
                productCode: productCode,
                codeType: codeType,
                raw: raw,
                serialNumber: serialNumber,
                lot: lot,
                expiry: expiry,
                createdAt: createdAt,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ScanEventsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sessionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (sessionId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.sessionId,
                                referencedTable: $$ScanEventsTableReferences
                                    ._sessionIdTable(db),
                                referencedColumn: $$ScanEventsTableReferences
                                    ._sessionIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ScanEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ScanEventsTable,
      ScanEventRow,
      $$ScanEventsTableFilterComposer,
      $$ScanEventsTableOrderingComposer,
      $$ScanEventsTableAnnotationComposer,
      $$ScanEventsTableCreateCompanionBuilder,
      $$ScanEventsTableUpdateCompanionBuilder,
      (ScanEventRow, $$ScanEventsTableReferences),
      ScanEventRow,
      PrefetchHooks Function({bool sessionId})
    >;
typedef $$MedicationCatalogEntriesTableCreateCompanionBuilder =
    MedicationCatalogEntriesCompanion Function({
      required String id,
      required String sourceName,
      required int sourcePriority,
      required String sourceRecordId,
      required String canonicalCode,
      required String displayName,
      Value<String?> activeSubstance,
      Value<String?> strength,
      Value<String?> pharmaceuticalForm,
      Value<String?> presentation,
      Value<String?> holder,
      Value<String?> leafletUrl,
      Value<String?> rcmUrl,
      Value<String?> sourceUrl,
      Value<String?> imageUrl,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$MedicationCatalogEntriesTableUpdateCompanionBuilder =
    MedicationCatalogEntriesCompanion Function({
      Value<String> id,
      Value<String> sourceName,
      Value<int> sourcePriority,
      Value<String> sourceRecordId,
      Value<String> canonicalCode,
      Value<String> displayName,
      Value<String?> activeSubstance,
      Value<String?> strength,
      Value<String?> pharmaceuticalForm,
      Value<String?> presentation,
      Value<String?> holder,
      Value<String?> leafletUrl,
      Value<String?> rcmUrl,
      Value<String?> sourceUrl,
      Value<String?> imageUrl,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$MedicationCatalogEntriesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $MedicationCatalogEntriesTable,
          MedicationCatalogEntryRow
        > {
  $$MedicationCatalogEntriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<
    $MedicationLookupCodesTable,
    List<MedicationLookupCodeRow>
  >
  _medicationLookupCodesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.medicationLookupCodes,
        aliasName: $_aliasNameGenerator(
          db.medicationCatalogEntries.id,
          db.medicationLookupCodes.medicationId,
        ),
      );

  $$MedicationLookupCodesTableProcessedTableManager
  get medicationLookupCodesRefs {
    final manager = $$MedicationLookupCodesTableTableManager(
      $_db,
      $_db.medicationLookupCodes,
    ).filter((f) => f.medicationId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _medicationLookupCodesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$MedicationCatalogEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $MedicationCatalogEntriesTable> {
  $$MedicationCatalogEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceName => $composableBuilder(
    column: $table.sourceName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sourcePriority => $composableBuilder(
    column: $table.sourcePriority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceRecordId => $composableBuilder(
    column: $table.sourceRecordId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get canonicalCode => $composableBuilder(
    column: $table.canonicalCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get activeSubstance => $composableBuilder(
    column: $table.activeSubstance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get strength => $composableBuilder(
    column: $table.strength,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pharmaceuticalForm => $composableBuilder(
    column: $table.pharmaceuticalForm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get presentation => $composableBuilder(
    column: $table.presentation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get holder => $composableBuilder(
    column: $table.holder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get leafletUrl => $composableBuilder(
    column: $table.leafletUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rcmUrl => $composableBuilder(
    column: $table.rcmUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceUrl => $composableBuilder(
    column: $table.sourceUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> medicationLookupCodesRefs(
    Expression<bool> Function($$MedicationLookupCodesTableFilterComposer f) f,
  ) {
    final $$MedicationLookupCodesTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.medicationLookupCodes,
          getReferencedColumn: (t) => t.medicationId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$MedicationLookupCodesTableFilterComposer(
                $db: $db,
                $table: $db.medicationLookupCodes,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$MedicationCatalogEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $MedicationCatalogEntriesTable> {
  $$MedicationCatalogEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceName => $composableBuilder(
    column: $table.sourceName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sourcePriority => $composableBuilder(
    column: $table.sourcePriority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceRecordId => $composableBuilder(
    column: $table.sourceRecordId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get canonicalCode => $composableBuilder(
    column: $table.canonicalCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get activeSubstance => $composableBuilder(
    column: $table.activeSubstance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get strength => $composableBuilder(
    column: $table.strength,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pharmaceuticalForm => $composableBuilder(
    column: $table.pharmaceuticalForm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get presentation => $composableBuilder(
    column: $table.presentation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get holder => $composableBuilder(
    column: $table.holder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get leafletUrl => $composableBuilder(
    column: $table.leafletUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rcmUrl => $composableBuilder(
    column: $table.rcmUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceUrl => $composableBuilder(
    column: $table.sourceUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MedicationCatalogEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MedicationCatalogEntriesTable> {
  $$MedicationCatalogEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sourceName => $composableBuilder(
    column: $table.sourceName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sourcePriority => $composableBuilder(
    column: $table.sourcePriority,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceRecordId => $composableBuilder(
    column: $table.sourceRecordId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get canonicalCode => $composableBuilder(
    column: $table.canonicalCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get activeSubstance => $composableBuilder(
    column: $table.activeSubstance,
    builder: (column) => column,
  );

  GeneratedColumn<String> get strength =>
      $composableBuilder(column: $table.strength, builder: (column) => column);

  GeneratedColumn<String> get pharmaceuticalForm => $composableBuilder(
    column: $table.pharmaceuticalForm,
    builder: (column) => column,
  );

  GeneratedColumn<String> get presentation => $composableBuilder(
    column: $table.presentation,
    builder: (column) => column,
  );

  GeneratedColumn<String> get holder =>
      $composableBuilder(column: $table.holder, builder: (column) => column);

  GeneratedColumn<String> get leafletUrl => $composableBuilder(
    column: $table.leafletUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rcmUrl =>
      $composableBuilder(column: $table.rcmUrl, builder: (column) => column);

  GeneratedColumn<String> get sourceUrl =>
      $composableBuilder(column: $table.sourceUrl, builder: (column) => column);

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> medicationLookupCodesRefs<T extends Object>(
    Expression<T> Function($$MedicationLookupCodesTableAnnotationComposer a) f,
  ) {
    final $$MedicationLookupCodesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.medicationLookupCodes,
          getReferencedColumn: (t) => t.medicationId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$MedicationLookupCodesTableAnnotationComposer(
                $db: $db,
                $table: $db.medicationLookupCodes,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$MedicationCatalogEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MedicationCatalogEntriesTable,
          MedicationCatalogEntryRow,
          $$MedicationCatalogEntriesTableFilterComposer,
          $$MedicationCatalogEntriesTableOrderingComposer,
          $$MedicationCatalogEntriesTableAnnotationComposer,
          $$MedicationCatalogEntriesTableCreateCompanionBuilder,
          $$MedicationCatalogEntriesTableUpdateCompanionBuilder,
          (
            MedicationCatalogEntryRow,
            $$MedicationCatalogEntriesTableReferences,
          ),
          MedicationCatalogEntryRow,
          PrefetchHooks Function({bool medicationLookupCodesRefs})
        > {
  $$MedicationCatalogEntriesTableTableManager(
    _$AppDatabase db,
    $MedicationCatalogEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MedicationCatalogEntriesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$MedicationCatalogEntriesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$MedicationCatalogEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sourceName = const Value.absent(),
                Value<int> sourcePriority = const Value.absent(),
                Value<String> sourceRecordId = const Value.absent(),
                Value<String> canonicalCode = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String?> activeSubstance = const Value.absent(),
                Value<String?> strength = const Value.absent(),
                Value<String?> pharmaceuticalForm = const Value.absent(),
                Value<String?> presentation = const Value.absent(),
                Value<String?> holder = const Value.absent(),
                Value<String?> leafletUrl = const Value.absent(),
                Value<String?> rcmUrl = const Value.absent(),
                Value<String?> sourceUrl = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MedicationCatalogEntriesCompanion(
                id: id,
                sourceName: sourceName,
                sourcePriority: sourcePriority,
                sourceRecordId: sourceRecordId,
                canonicalCode: canonicalCode,
                displayName: displayName,
                activeSubstance: activeSubstance,
                strength: strength,
                pharmaceuticalForm: pharmaceuticalForm,
                presentation: presentation,
                holder: holder,
                leafletUrl: leafletUrl,
                rcmUrl: rcmUrl,
                sourceUrl: sourceUrl,
                imageUrl: imageUrl,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sourceName,
                required int sourcePriority,
                required String sourceRecordId,
                required String canonicalCode,
                required String displayName,
                Value<String?> activeSubstance = const Value.absent(),
                Value<String?> strength = const Value.absent(),
                Value<String?> pharmaceuticalForm = const Value.absent(),
                Value<String?> presentation = const Value.absent(),
                Value<String?> holder = const Value.absent(),
                Value<String?> leafletUrl = const Value.absent(),
                Value<String?> rcmUrl = const Value.absent(),
                Value<String?> sourceUrl = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => MedicationCatalogEntriesCompanion.insert(
                id: id,
                sourceName: sourceName,
                sourcePriority: sourcePriority,
                sourceRecordId: sourceRecordId,
                canonicalCode: canonicalCode,
                displayName: displayName,
                activeSubstance: activeSubstance,
                strength: strength,
                pharmaceuticalForm: pharmaceuticalForm,
                presentation: presentation,
                holder: holder,
                leafletUrl: leafletUrl,
                rcmUrl: rcmUrl,
                sourceUrl: sourceUrl,
                imageUrl: imageUrl,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$MedicationCatalogEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({medicationLookupCodesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (medicationLookupCodesRefs) db.medicationLookupCodes,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (medicationLookupCodesRefs)
                    await $_getPrefetchedData<
                      MedicationCatalogEntryRow,
                      $MedicationCatalogEntriesTable,
                      MedicationLookupCodeRow
                    >(
                      currentTable: table,
                      referencedTable: $$MedicationCatalogEntriesTableReferences
                          ._medicationLookupCodesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$MedicationCatalogEntriesTableReferences(
                            db,
                            table,
                            p0,
                          ).medicationLookupCodesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.medicationId == item.id,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$MedicationCatalogEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MedicationCatalogEntriesTable,
      MedicationCatalogEntryRow,
      $$MedicationCatalogEntriesTableFilterComposer,
      $$MedicationCatalogEntriesTableOrderingComposer,
      $$MedicationCatalogEntriesTableAnnotationComposer,
      $$MedicationCatalogEntriesTableCreateCompanionBuilder,
      $$MedicationCatalogEntriesTableUpdateCompanionBuilder,
      (MedicationCatalogEntryRow, $$MedicationCatalogEntriesTableReferences),
      MedicationCatalogEntryRow,
      PrefetchHooks Function({bool medicationLookupCodesRefs})
    >;
typedef $$MedicationLookupCodesTableCreateCompanionBuilder =
    MedicationLookupCodesCompanion Function({
      required String id,
      required String medicationId,
      required String normalizedCode,
      required String codeKind,
      Value<bool> isPrimary,
      Value<int> rowid,
    });
typedef $$MedicationLookupCodesTableUpdateCompanionBuilder =
    MedicationLookupCodesCompanion Function({
      Value<String> id,
      Value<String> medicationId,
      Value<String> normalizedCode,
      Value<String> codeKind,
      Value<bool> isPrimary,
      Value<int> rowid,
    });

final class $$MedicationLookupCodesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $MedicationLookupCodesTable,
          MedicationLookupCodeRow
        > {
  $$MedicationLookupCodesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $MedicationCatalogEntriesTable _medicationIdTable(_$AppDatabase db) =>
      db.medicationCatalogEntries.createAlias(
        $_aliasNameGenerator(
          db.medicationLookupCodes.medicationId,
          db.medicationCatalogEntries.id,
        ),
      );

  $$MedicationCatalogEntriesTableProcessedTableManager get medicationId {
    final $_column = $_itemColumn<String>('medication_id')!;

    final manager = $$MedicationCatalogEntriesTableTableManager(
      $_db,
      $_db.medicationCatalogEntries,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_medicationIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$MedicationLookupCodesTableFilterComposer
    extends Composer<_$AppDatabase, $MedicationLookupCodesTable> {
  $$MedicationLookupCodesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get normalizedCode => $composableBuilder(
    column: $table.normalizedCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get codeKind => $composableBuilder(
    column: $table.codeKind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPrimary => $composableBuilder(
    column: $table.isPrimary,
    builder: (column) => ColumnFilters(column),
  );

  $$MedicationCatalogEntriesTableFilterComposer get medicationId {
    final $$MedicationCatalogEntriesTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.medicationId,
          referencedTable: $db.medicationCatalogEntries,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$MedicationCatalogEntriesTableFilterComposer(
                $db: $db,
                $table: $db.medicationCatalogEntries,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$MedicationLookupCodesTableOrderingComposer
    extends Composer<_$AppDatabase, $MedicationLookupCodesTable> {
  $$MedicationLookupCodesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get normalizedCode => $composableBuilder(
    column: $table.normalizedCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get codeKind => $composableBuilder(
    column: $table.codeKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPrimary => $composableBuilder(
    column: $table.isPrimary,
    builder: (column) => ColumnOrderings(column),
  );

  $$MedicationCatalogEntriesTableOrderingComposer get medicationId {
    final $$MedicationCatalogEntriesTableOrderingComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.medicationId,
          referencedTable: $db.medicationCatalogEntries,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$MedicationCatalogEntriesTableOrderingComposer(
                $db: $db,
                $table: $db.medicationCatalogEntries,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$MedicationLookupCodesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MedicationLookupCodesTable> {
  $$MedicationLookupCodesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get normalizedCode => $composableBuilder(
    column: $table.normalizedCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get codeKind =>
      $composableBuilder(column: $table.codeKind, builder: (column) => column);

  GeneratedColumn<bool> get isPrimary =>
      $composableBuilder(column: $table.isPrimary, builder: (column) => column);

  $$MedicationCatalogEntriesTableAnnotationComposer get medicationId {
    final $$MedicationCatalogEntriesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.medicationId,
          referencedTable: $db.medicationCatalogEntries,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$MedicationCatalogEntriesTableAnnotationComposer(
                $db: $db,
                $table: $db.medicationCatalogEntries,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$MedicationLookupCodesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MedicationLookupCodesTable,
          MedicationLookupCodeRow,
          $$MedicationLookupCodesTableFilterComposer,
          $$MedicationLookupCodesTableOrderingComposer,
          $$MedicationLookupCodesTableAnnotationComposer,
          $$MedicationLookupCodesTableCreateCompanionBuilder,
          $$MedicationLookupCodesTableUpdateCompanionBuilder,
          (MedicationLookupCodeRow, $$MedicationLookupCodesTableReferences),
          MedicationLookupCodeRow,
          PrefetchHooks Function({bool medicationId})
        > {
  $$MedicationLookupCodesTableTableManager(
    _$AppDatabase db,
    $MedicationLookupCodesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MedicationLookupCodesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$MedicationLookupCodesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$MedicationLookupCodesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> medicationId = const Value.absent(),
                Value<String> normalizedCode = const Value.absent(),
                Value<String> codeKind = const Value.absent(),
                Value<bool> isPrimary = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MedicationLookupCodesCompanion(
                id: id,
                medicationId: medicationId,
                normalizedCode: normalizedCode,
                codeKind: codeKind,
                isPrimary: isPrimary,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String medicationId,
                required String normalizedCode,
                required String codeKind,
                Value<bool> isPrimary = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MedicationLookupCodesCompanion.insert(
                id: id,
                medicationId: medicationId,
                normalizedCode: normalizedCode,
                codeKind: codeKind,
                isPrimary: isPrimary,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$MedicationLookupCodesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({medicationId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (medicationId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.medicationId,
                                referencedTable:
                                    $$MedicationLookupCodesTableReferences
                                        ._medicationIdTable(db),
                                referencedColumn:
                                    $$MedicationLookupCodesTableReferences
                                        ._medicationIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$MedicationLookupCodesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MedicationLookupCodesTable,
      MedicationLookupCodeRow,
      $$MedicationLookupCodesTableFilterComposer,
      $$MedicationLookupCodesTableOrderingComposer,
      $$MedicationLookupCodesTableAnnotationComposer,
      $$MedicationLookupCodesTableCreateCompanionBuilder,
      $$MedicationLookupCodesTableUpdateCompanionBuilder,
      (MedicationLookupCodeRow, $$MedicationLookupCodesTableReferences),
      MedicationLookupCodeRow,
      PrefetchHooks Function({bool medicationId})
    >;
typedef $$MedicationEnrichmentStatusesTableCreateCompanionBuilder =
    MedicationEnrichmentStatusesCompanion Function({
      required String id,
      required String normalizedCode,
      required String codeKind,
      Value<DateTime?> lastAttemptedAt,
      Value<DateTime?> lastSucceededAt,
      Value<DateTime?> lastFailedAt,
      Value<int> attemptCount,
      Value<DateTime?> nextRetryAt,
      Value<String?> lastError,
      Value<String?> lastProviderName,
      Value<int> rowid,
    });
typedef $$MedicationEnrichmentStatusesTableUpdateCompanionBuilder =
    MedicationEnrichmentStatusesCompanion Function({
      Value<String> id,
      Value<String> normalizedCode,
      Value<String> codeKind,
      Value<DateTime?> lastAttemptedAt,
      Value<DateTime?> lastSucceededAt,
      Value<DateTime?> lastFailedAt,
      Value<int> attemptCount,
      Value<DateTime?> nextRetryAt,
      Value<String?> lastError,
      Value<String?> lastProviderName,
      Value<int> rowid,
    });

class $$MedicationEnrichmentStatusesTableFilterComposer
    extends Composer<_$AppDatabase, $MedicationEnrichmentStatusesTable> {
  $$MedicationEnrichmentStatusesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get normalizedCode => $composableBuilder(
    column: $table.normalizedCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get codeKind => $composableBuilder(
    column: $table.codeKind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastAttemptedAt => $composableBuilder(
    column: $table.lastAttemptedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSucceededAt => $composableBuilder(
    column: $table.lastSucceededAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastFailedAt => $composableBuilder(
    column: $table.lastFailedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextRetryAt => $composableBuilder(
    column: $table.nextRetryAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastProviderName => $composableBuilder(
    column: $table.lastProviderName,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MedicationEnrichmentStatusesTableOrderingComposer
    extends Composer<_$AppDatabase, $MedicationEnrichmentStatusesTable> {
  $$MedicationEnrichmentStatusesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get normalizedCode => $composableBuilder(
    column: $table.normalizedCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get codeKind => $composableBuilder(
    column: $table.codeKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastAttemptedAt => $composableBuilder(
    column: $table.lastAttemptedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSucceededAt => $composableBuilder(
    column: $table.lastSucceededAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastFailedAt => $composableBuilder(
    column: $table.lastFailedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextRetryAt => $composableBuilder(
    column: $table.nextRetryAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastProviderName => $composableBuilder(
    column: $table.lastProviderName,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MedicationEnrichmentStatusesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MedicationEnrichmentStatusesTable> {
  $$MedicationEnrichmentStatusesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get normalizedCode => $composableBuilder(
    column: $table.normalizedCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get codeKind =>
      $composableBuilder(column: $table.codeKind, builder: (column) => column);

  GeneratedColumn<DateTime> get lastAttemptedAt => $composableBuilder(
    column: $table.lastAttemptedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastSucceededAt => $composableBuilder(
    column: $table.lastSucceededAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastFailedAt => $composableBuilder(
    column: $table.lastFailedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get nextRetryAt => $composableBuilder(
    column: $table.nextRetryAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<String> get lastProviderName => $composableBuilder(
    column: $table.lastProviderName,
    builder: (column) => column,
  );
}

class $$MedicationEnrichmentStatusesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MedicationEnrichmentStatusesTable,
          MedicationEnrichmentStatusRow,
          $$MedicationEnrichmentStatusesTableFilterComposer,
          $$MedicationEnrichmentStatusesTableOrderingComposer,
          $$MedicationEnrichmentStatusesTableAnnotationComposer,
          $$MedicationEnrichmentStatusesTableCreateCompanionBuilder,
          $$MedicationEnrichmentStatusesTableUpdateCompanionBuilder,
          (
            MedicationEnrichmentStatusRow,
            BaseReferences<
              _$AppDatabase,
              $MedicationEnrichmentStatusesTable,
              MedicationEnrichmentStatusRow
            >,
          ),
          MedicationEnrichmentStatusRow,
          PrefetchHooks Function()
        > {
  $$MedicationEnrichmentStatusesTableTableManager(
    _$AppDatabase db,
    $MedicationEnrichmentStatusesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MedicationEnrichmentStatusesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$MedicationEnrichmentStatusesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$MedicationEnrichmentStatusesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> normalizedCode = const Value.absent(),
                Value<String> codeKind = const Value.absent(),
                Value<DateTime?> lastAttemptedAt = const Value.absent(),
                Value<DateTime?> lastSucceededAt = const Value.absent(),
                Value<DateTime?> lastFailedAt = const Value.absent(),
                Value<int> attemptCount = const Value.absent(),
                Value<DateTime?> nextRetryAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<String?> lastProviderName = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MedicationEnrichmentStatusesCompanion(
                id: id,
                normalizedCode: normalizedCode,
                codeKind: codeKind,
                lastAttemptedAt: lastAttemptedAt,
                lastSucceededAt: lastSucceededAt,
                lastFailedAt: lastFailedAt,
                attemptCount: attemptCount,
                nextRetryAt: nextRetryAt,
                lastError: lastError,
                lastProviderName: lastProviderName,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String normalizedCode,
                required String codeKind,
                Value<DateTime?> lastAttemptedAt = const Value.absent(),
                Value<DateTime?> lastSucceededAt = const Value.absent(),
                Value<DateTime?> lastFailedAt = const Value.absent(),
                Value<int> attemptCount = const Value.absent(),
                Value<DateTime?> nextRetryAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<String?> lastProviderName = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MedicationEnrichmentStatusesCompanion.insert(
                id: id,
                normalizedCode: normalizedCode,
                codeKind: codeKind,
                lastAttemptedAt: lastAttemptedAt,
                lastSucceededAt: lastSucceededAt,
                lastFailedAt: lastFailedAt,
                attemptCount: attemptCount,
                nextRetryAt: nextRetryAt,
                lastError: lastError,
                lastProviderName: lastProviderName,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MedicationEnrichmentStatusesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MedicationEnrichmentStatusesTable,
      MedicationEnrichmentStatusRow,
      $$MedicationEnrichmentStatusesTableFilterComposer,
      $$MedicationEnrichmentStatusesTableOrderingComposer,
      $$MedicationEnrichmentStatusesTableAnnotationComposer,
      $$MedicationEnrichmentStatusesTableCreateCompanionBuilder,
      $$MedicationEnrichmentStatusesTableUpdateCompanionBuilder,
      (
        MedicationEnrichmentStatusRow,
        BaseReferences<
          _$AppDatabase,
          $MedicationEnrichmentStatusesTable,
          MedicationEnrichmentStatusRow
        >,
      ),
      MedicationEnrichmentStatusRow,
      PrefetchHooks Function()
    >;
typedef $$MedicationCatalogStateTableTableCreateCompanionBuilder =
    MedicationCatalogStateTableCompanion Function({
      required String id,
      Value<DateTime?> csvLastImportedAt,
      Value<int> csvEntryCount,
      Value<String?> csvSourceLabel,
      Value<int> rowid,
    });
typedef $$MedicationCatalogStateTableTableUpdateCompanionBuilder =
    MedicationCatalogStateTableCompanion Function({
      Value<String> id,
      Value<DateTime?> csvLastImportedAt,
      Value<int> csvEntryCount,
      Value<String?> csvSourceLabel,
      Value<int> rowid,
    });

class $$MedicationCatalogStateTableTableFilterComposer
    extends Composer<_$AppDatabase, $MedicationCatalogStateTableTable> {
  $$MedicationCatalogStateTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get csvLastImportedAt => $composableBuilder(
    column: $table.csvLastImportedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get csvEntryCount => $composableBuilder(
    column: $table.csvEntryCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get csvSourceLabel => $composableBuilder(
    column: $table.csvSourceLabel,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MedicationCatalogStateTableTableOrderingComposer
    extends Composer<_$AppDatabase, $MedicationCatalogStateTableTable> {
  $$MedicationCatalogStateTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get csvLastImportedAt => $composableBuilder(
    column: $table.csvLastImportedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get csvEntryCount => $composableBuilder(
    column: $table.csvEntryCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get csvSourceLabel => $composableBuilder(
    column: $table.csvSourceLabel,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MedicationCatalogStateTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $MedicationCatalogStateTableTable> {
  $$MedicationCatalogStateTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get csvLastImportedAt => $composableBuilder(
    column: $table.csvLastImportedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get csvEntryCount => $composableBuilder(
    column: $table.csvEntryCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get csvSourceLabel => $composableBuilder(
    column: $table.csvSourceLabel,
    builder: (column) => column,
  );
}

class $$MedicationCatalogStateTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MedicationCatalogStateTableTable,
          MedicationCatalogStateRow,
          $$MedicationCatalogStateTableTableFilterComposer,
          $$MedicationCatalogStateTableTableOrderingComposer,
          $$MedicationCatalogStateTableTableAnnotationComposer,
          $$MedicationCatalogStateTableTableCreateCompanionBuilder,
          $$MedicationCatalogStateTableTableUpdateCompanionBuilder,
          (
            MedicationCatalogStateRow,
            BaseReferences<
              _$AppDatabase,
              $MedicationCatalogStateTableTable,
              MedicationCatalogStateRow
            >,
          ),
          MedicationCatalogStateRow,
          PrefetchHooks Function()
        > {
  $$MedicationCatalogStateTableTableTableManager(
    _$AppDatabase db,
    $MedicationCatalogStateTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MedicationCatalogStateTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$MedicationCatalogStateTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$MedicationCatalogStateTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime?> csvLastImportedAt = const Value.absent(),
                Value<int> csvEntryCount = const Value.absent(),
                Value<String?> csvSourceLabel = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MedicationCatalogStateTableCompanion(
                id: id,
                csvLastImportedAt: csvLastImportedAt,
                csvEntryCount: csvEntryCount,
                csvSourceLabel: csvSourceLabel,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<DateTime?> csvLastImportedAt = const Value.absent(),
                Value<int> csvEntryCount = const Value.absent(),
                Value<String?> csvSourceLabel = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MedicationCatalogStateTableCompanion.insert(
                id: id,
                csvLastImportedAt: csvLastImportedAt,
                csvEntryCount: csvEntryCount,
                csvSourceLabel: csvSourceLabel,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MedicationCatalogStateTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MedicationCatalogStateTableTable,
      MedicationCatalogStateRow,
      $$MedicationCatalogStateTableTableFilterComposer,
      $$MedicationCatalogStateTableTableOrderingComposer,
      $$MedicationCatalogStateTableTableAnnotationComposer,
      $$MedicationCatalogStateTableTableCreateCompanionBuilder,
      $$MedicationCatalogStateTableTableUpdateCompanionBuilder,
      (
        MedicationCatalogStateRow,
        BaseReferences<
          _$AppDatabase,
          $MedicationCatalogStateTableTable,
          MedicationCatalogStateRow
        >,
      ),
      MedicationCatalogStateRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$InventorySessionsTableTableManager get inventorySessions =>
      $$InventorySessionsTableTableManager(_db, _db.inventorySessions);
  $$ScanEventsTableTableManager get scanEvents =>
      $$ScanEventsTableTableManager(_db, _db.scanEvents);
  $$MedicationCatalogEntriesTableTableManager get medicationCatalogEntries =>
      $$MedicationCatalogEntriesTableTableManager(
        _db,
        _db.medicationCatalogEntries,
      );
  $$MedicationLookupCodesTableTableManager get medicationLookupCodes =>
      $$MedicationLookupCodesTableTableManager(_db, _db.medicationLookupCodes);
  $$MedicationEnrichmentStatusesTableTableManager
  get medicationEnrichmentStatuses =>
      $$MedicationEnrichmentStatusesTableTableManager(
        _db,
        _db.medicationEnrichmentStatuses,
      );
  $$MedicationCatalogStateTableTableTableManager
  get medicationCatalogStateTable =>
      $$MedicationCatalogStateTableTableTableManager(
        _db,
        _db.medicationCatalogStateTable,
      );
}
