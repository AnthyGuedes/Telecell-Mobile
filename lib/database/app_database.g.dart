part of 'app_database.dart';

// ignore_for_file: type=lint
class $ClientesTable extends Clientes with TableInfo<$ClientesTable, Cliente> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ClientesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nomeMeta = const VerificationMeta('nome');
  @override
  late final GeneratedColumn<String> nome = GeneratedColumn<String>(
    'nome',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _telefoneMeta = const VerificationMeta(
    'telefone',
  );
  @override
  late final GeneratedColumn<String> telefone = GeneratedColumn<String>(
    'telefone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cpfMeta = const VerificationMeta('cpf');
  @override
  late final GeneratedColumn<String> cpf = GeneratedColumn<String>(
    'cpf',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, nome, telefone, cpf];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'clientes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Cliente> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('nome')) {
      context.handle(
        _nomeMeta,
        nome.isAcceptableOrUnknown(data['nome']!, _nomeMeta),
      );
    } else if (isInserting) {
      context.missing(_nomeMeta);
    }
    if (data.containsKey('telefone')) {
      context.handle(
        _telefoneMeta,
        telefone.isAcceptableOrUnknown(data['telefone']!, _telefoneMeta),
      );
    } else if (isInserting) {
      context.missing(_telefoneMeta);
    }
    if (data.containsKey('cpf')) {
      context.handle(
        _cpfMeta,
        cpf.isAcceptableOrUnknown(data['cpf']!, _cpfMeta),
      );
    } else if (isInserting) {
      context.missing(_cpfMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Cliente map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Cliente(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      nome: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nome'],
      )!,
      telefone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}telefone'],
      )!,
      cpf: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cpf'],
      )!,
    );
  }

  @override
  $ClientesTable createAlias(String alias) {
    return $ClientesTable(attachedDatabase, alias);
  }
}

class Cliente extends DataClass implements Insertable<Cliente> {
  final int id;
  final String nome;
  final String telefone;
  final String cpf;
  const Cliente({
    required this.id,
    required this.nome,
    required this.telefone,
    required this.cpf,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['nome'] = Variable<String>(nome);
    map['telefone'] = Variable<String>(telefone);
    map['cpf'] = Variable<String>(cpf);
    return map;
  }

  ClientesCompanion toCompanion(bool nullToAbsent) {
    return ClientesCompanion(
      id: Value(id),
      nome: Value(nome),
      telefone: Value(telefone),
      cpf: Value(cpf),
    );
  }

  factory Cliente.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Cliente(
      id: serializer.fromJson<int>(json['id']),
      nome: serializer.fromJson<String>(json['nome']),
      telefone: serializer.fromJson<String>(json['telefone']),
      cpf: serializer.fromJson<String>(json['cpf']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'nome': serializer.toJson<String>(nome),
      'telefone': serializer.toJson<String>(telefone),
      'cpf': serializer.toJson<String>(cpf),
    };
  }

  Cliente copyWith({int? id, String? nome, String? telefone, String? cpf}) =>
      Cliente(
        id: id ?? this.id,
        nome: nome ?? this.nome,
        telefone: telefone ?? this.telefone,
        cpf: cpf ?? this.cpf,
      );
  Cliente copyWithCompanion(ClientesCompanion data) {
    return Cliente(
      id: data.id.present ? data.id.value : this.id,
      nome: data.nome.present ? data.nome.value : this.nome,
      telefone: data.telefone.present ? data.telefone.value : this.telefone,
      cpf: data.cpf.present ? data.cpf.value : this.cpf,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Cliente(')
          ..write('id: $id, ')
          ..write('nome: $nome, ')
          ..write('telefone: $telefone, ')
          ..write('cpf: $cpf')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, nome, telefone, cpf);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Cliente &&
          other.id == this.id &&
          other.nome == this.nome &&
          other.telefone == this.telefone &&
          other.cpf == this.cpf);
}

class ClientesCompanion extends UpdateCompanion<Cliente> {
  final Value<int> id;
  final Value<String> nome;
  final Value<String> telefone;
  final Value<String> cpf;
  const ClientesCompanion({
    this.id = const Value.absent(),
    this.nome = const Value.absent(),
    this.telefone = const Value.absent(),
    this.cpf = const Value.absent(),
  });
  ClientesCompanion.insert({
    this.id = const Value.absent(),
    required String nome,
    required String telefone,
    required String cpf,
  }) : nome = Value(nome),
       telefone = Value(telefone),
       cpf = Value(cpf);
  static Insertable<Cliente> custom({
    Expression<int>? id,
    Expression<String>? nome,
    Expression<String>? telefone,
    Expression<String>? cpf,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nome != null) 'nome': nome,
      if (telefone != null) 'telefone': telefone,
      if (cpf != null) 'cpf': cpf,
    });
  }

  ClientesCompanion copyWith({
    Value<int>? id,
    Value<String>? nome,
    Value<String>? telefone,
    Value<String>? cpf,
  }) {
    return ClientesCompanion(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      telefone: telefone ?? this.telefone,
      cpf: cpf ?? this.cpf,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (nome.present) {
      map['nome'] = Variable<String>(nome.value);
    }
    if (telefone.present) {
      map['telefone'] = Variable<String>(telefone.value);
    }
    if (cpf.present) {
      map['cpf'] = Variable<String>(cpf.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ClientesCompanion(')
          ..write('id: $id, ')
          ..write('nome: $nome, ')
          ..write('telefone: $telefone, ')
          ..write('cpf: $cpf')
          ..write(')'))
        .toString();
  }
}

class $OrdensServicoTable extends OrdensServico
    with TableInfo<$OrdensServicoTable, OrdemDeServico> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OrdensServicoTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _clienteIdMeta = const VerificationMeta(
    'clienteId',
  );
  @override
  late final GeneratedColumn<int> clienteId = GeneratedColumn<int>(
    'cliente_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES clientes (id)',
    ),
  );
  static const VerificationMeta _tipoRegistroMeta = const VerificationMeta(
    'tipoRegistro',
  );
  @override
  late final GeneratedColumn<String> tipoRegistro = GeneratedColumn<String>(
    'tipo_registro',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dataEntradaMeta = const VerificationMeta(
    'dataEntrada',
  );
  @override
  late final GeneratedColumn<DateTime> dataEntrada = GeneratedColumn<DateTime>(
    'data_entrada',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _marcaModeloMeta = const VerificationMeta(
    'marcaModelo',
  );
  @override
  late final GeneratedColumn<String> marcaModelo = GeneratedColumn<String>(
    'marca_modelo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _imeiMeta = const VerificationMeta('imei');
  @override
  late final GeneratedColumn<String> imei = GeneratedColumn<String>(
    'imei',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _senhaDesbloqueioMeta = const VerificationMeta(
    'senhaDesbloqueio',
  );
  @override
  late final GeneratedColumn<String> senhaDesbloqueio = GeneratedColumn<String>(
    'senha_desbloqueio',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _checkDisplayMeta = const VerificationMeta(
    'checkDisplay',
  );
  @override
  late final GeneratedColumn<bool> checkDisplay = GeneratedColumn<bool>(
    'check_display',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("check_display" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _checkTouchMeta = const VerificationMeta(
    'checkTouch',
  );
  @override
  late final GeneratedColumn<bool> checkTouch = GeneratedColumn<bool>(
    'check_touch',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("check_touch" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _problemaRelatadoMeta = const VerificationMeta(
    'problemaRelatado',
  );
  @override
  late final GeneratedColumn<String> problemaRelatado = GeneratedColumn<String>(
    'problema_relatado',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _servicoExecutadoMeta = const VerificationMeta(
    'servicoExecutado',
  );
  @override
  late final GeneratedColumn<String> servicoExecutado = GeneratedColumn<String>(
    'servico_executado',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _valorMeta = const VerificationMeta('valor');
  @override
  late final GeneratedColumn<double> valor = GeneratedColumn<double>(
    'valor',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Aberta'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    clienteId,
    tipoRegistro,
    dataEntrada,
    marcaModelo,
    imei,
    senhaDesbloqueio,
    checkDisplay,
    checkTouch,
    problemaRelatado,
    servicoExecutado,
    valor,
    status,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ordens_servico';
  @override
  VerificationContext validateIntegrity(
    Insertable<OrdemDeServico> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('cliente_id')) {
      context.handle(
        _clienteIdMeta,
        clienteId.isAcceptableOrUnknown(data['cliente_id']!, _clienteIdMeta),
      );
    } else if (isInserting) {
      context.missing(_clienteIdMeta);
    }
    if (data.containsKey('tipo_registro')) {
      context.handle(
        _tipoRegistroMeta,
        tipoRegistro.isAcceptableOrUnknown(
          data['tipo_registro']!,
          _tipoRegistroMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_tipoRegistroMeta);
    }
    if (data.containsKey('data_entrada')) {
      context.handle(
        _dataEntradaMeta,
        dataEntrada.isAcceptableOrUnknown(
          data['data_entrada']!,
          _dataEntradaMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dataEntradaMeta);
    }
    if (data.containsKey('marca_modelo')) {
      context.handle(
        _marcaModeloMeta,
        marcaModelo.isAcceptableOrUnknown(
          data['marca_modelo']!,
          _marcaModeloMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_marcaModeloMeta);
    }
    if (data.containsKey('imei')) {
      context.handle(
        _imeiMeta,
        imei.isAcceptableOrUnknown(data['imei']!, _imeiMeta),
      );
    } else if (isInserting) {
      context.missing(_imeiMeta);
    }
    if (data.containsKey('senha_desbloqueio')) {
      context.handle(
        _senhaDesbloqueioMeta,
        senhaDesbloqueio.isAcceptableOrUnknown(
          data['senha_desbloqueio']!,
          _senhaDesbloqueioMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_senhaDesbloqueioMeta);
    }
    if (data.containsKey('check_display')) {
      context.handle(
        _checkDisplayMeta,
        checkDisplay.isAcceptableOrUnknown(
          data['check_display']!,
          _checkDisplayMeta,
        ),
      );
    }
    if (data.containsKey('check_touch')) {
      context.handle(
        _checkTouchMeta,
        checkTouch.isAcceptableOrUnknown(data['check_touch']!, _checkTouchMeta),
      );
    }
    if (data.containsKey('problema_relatado')) {
      context.handle(
        _problemaRelatadoMeta,
        problemaRelatado.isAcceptableOrUnknown(
          data['problema_relatado']!,
          _problemaRelatadoMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_problemaRelatadoMeta);
    }
    if (data.containsKey('servico_executado')) {
      context.handle(
        _servicoExecutadoMeta,
        servicoExecutado.isAcceptableOrUnknown(
          data['servico_executado']!,
          _servicoExecutadoMeta,
        ),
      );
    }
    if (data.containsKey('valor')) {
      context.handle(
        _valorMeta,
        valor.isAcceptableOrUnknown(data['valor']!, _valorMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OrdemDeServico map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OrdemDeServico(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      clienteId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cliente_id'],
      )!,
      tipoRegistro: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tipo_registro'],
      )!,
      dataEntrada: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}data_entrada'],
      )!,
      marcaModelo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}marca_modelo'],
      )!,
      imei: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}imei'],
      )!,
      senhaDesbloqueio: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}senha_desbloqueio'],
      )!,
      checkDisplay: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}check_display'],
      )!,
      checkTouch: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}check_touch'],
      )!,
      problemaRelatado: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}problema_relatado'],
      )!,
      servicoExecutado: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}servico_executado'],
      ),
      valor: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}valor'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
    );
  }

  @override
  $OrdensServicoTable createAlias(String alias) {
    return $OrdensServicoTable(attachedDatabase, alias);
  }
}

class OrdemDeServico extends DataClass implements Insertable<OrdemDeServico> {
  final int id;
  final int clienteId;
  final String tipoRegistro;
  final DateTime dataEntrada;
  final String marcaModelo;
  final String imei;
  final String senhaDesbloqueio;
  final bool checkDisplay;
  final bool checkTouch;
  final String problemaRelatado;
  final String? servicoExecutado;
  final double? valor;
  final String status;
  const OrdemDeServico({
    required this.id,
    required this.clienteId,
    required this.tipoRegistro,
    required this.dataEntrada,
    required this.marcaModelo,
    required this.imei,
    required this.senhaDesbloqueio,
    required this.checkDisplay,
    required this.checkTouch,
    required this.problemaRelatado,
    this.servicoExecutado,
    this.valor,
    required this.status,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['cliente_id'] = Variable<int>(clienteId);
    map['tipo_registro'] = Variable<String>(tipoRegistro);
    map['data_entrada'] = Variable<DateTime>(dataEntrada);
    map['marca_modelo'] = Variable<String>(marcaModelo);
    map['imei'] = Variable<String>(imei);
    map['senha_desbloqueio'] = Variable<String>(senhaDesbloqueio);
    map['check_display'] = Variable<bool>(checkDisplay);
    map['check_touch'] = Variable<bool>(checkTouch);
    map['problema_relatado'] = Variable<String>(problemaRelatado);
    if (!nullToAbsent || servicoExecutado != null) {
      map['servico_executado'] = Variable<String>(servicoExecutado);
    }
    if (!nullToAbsent || valor != null) {
      map['valor'] = Variable<double>(valor);
    }
    map['status'] = Variable<String>(status);
    return map;
  }

  OrdensServicoCompanion toCompanion(bool nullToAbsent) {
    return OrdensServicoCompanion(
      id: Value(id),
      clienteId: Value(clienteId),
      tipoRegistro: Value(tipoRegistro),
      dataEntrada: Value(dataEntrada),
      marcaModelo: Value(marcaModelo),
      imei: Value(imei),
      senhaDesbloqueio: Value(senhaDesbloqueio),
      checkDisplay: Value(checkDisplay),
      checkTouch: Value(checkTouch),
      problemaRelatado: Value(problemaRelatado),
      servicoExecutado: servicoExecutado == null && nullToAbsent
          ? const Value.absent()
          : Value(servicoExecutado),
      valor: valor == null && nullToAbsent
          ? const Value.absent()
          : Value(valor),
      status: Value(status),
    );
  }

  factory OrdemDeServico.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OrdemDeServico(
      id: serializer.fromJson<int>(json['id']),
      clienteId: serializer.fromJson<int>(json['clienteId']),
      tipoRegistro: serializer.fromJson<String>(json['tipoRegistro']),
      dataEntrada: serializer.fromJson<DateTime>(json['dataEntrada']),
      marcaModelo: serializer.fromJson<String>(json['marcaModelo']),
      imei: serializer.fromJson<String>(json['imei']),
      senhaDesbloqueio: serializer.fromJson<String>(json['senhaDesbloqueio']),
      checkDisplay: serializer.fromJson<bool>(json['checkDisplay']),
      checkTouch: serializer.fromJson<bool>(json['checkTouch']),
      problemaRelatado: serializer.fromJson<String>(json['problemaRelatado']),
      servicoExecutado: serializer.fromJson<String?>(json['servicoExecutado']),
      valor: serializer.fromJson<double?>(json['valor']),
      status: serializer.fromJson<String>(json['status']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'clienteId': serializer.toJson<int>(clienteId),
      'tipoRegistro': serializer.toJson<String>(tipoRegistro),
      'dataEntrada': serializer.toJson<DateTime>(dataEntrada),
      'marcaModelo': serializer.toJson<String>(marcaModelo),
      'imei': serializer.toJson<String>(imei),
      'senhaDesbloqueio': serializer.toJson<String>(senhaDesbloqueio),
      'checkDisplay': serializer.toJson<bool>(checkDisplay),
      'checkTouch': serializer.toJson<bool>(checkTouch),
      'problemaRelatado': serializer.toJson<String>(problemaRelatado),
      'servicoExecutado': serializer.toJson<String?>(servicoExecutado),
      'valor': serializer.toJson<double?>(valor),
      'status': serializer.toJson<String>(status),
    };
  }

  OrdemDeServico copyWith({
    int? id,
    int? clienteId,
    String? tipoRegistro,
    DateTime? dataEntrada,
    String? marcaModelo,
    String? imei,
    String? senhaDesbloqueio,
    bool? checkDisplay,
    bool? checkTouch,
    String? problemaRelatado,
    Value<String?> servicoExecutado = const Value.absent(),
    Value<double?> valor = const Value.absent(),
    String? status,
  }) => OrdemDeServico(
    id: id ?? this.id,
    clienteId: clienteId ?? this.clienteId,
    tipoRegistro: tipoRegistro ?? this.tipoRegistro,
    dataEntrada: dataEntrada ?? this.dataEntrada,
    marcaModelo: marcaModelo ?? this.marcaModelo,
    imei: imei ?? this.imei,
    senhaDesbloqueio: senhaDesbloqueio ?? this.senhaDesbloqueio,
    checkDisplay: checkDisplay ?? this.checkDisplay,
    checkTouch: checkTouch ?? this.checkTouch,
    problemaRelatado: problemaRelatado ?? this.problemaRelatado,
    servicoExecutado: servicoExecutado.present
        ? servicoExecutado.value
        : this.servicoExecutado,
    valor: valor.present ? valor.value : this.valor,
    status: status ?? this.status,
  );
  OrdemDeServico copyWithCompanion(OrdensServicoCompanion data) {
    return OrdemDeServico(
      id: data.id.present ? data.id.value : this.id,
      clienteId: data.clienteId.present ? data.clienteId.value : this.clienteId,
      tipoRegistro: data.tipoRegistro.present
          ? data.tipoRegistro.value
          : this.tipoRegistro,
      dataEntrada: data.dataEntrada.present
          ? data.dataEntrada.value
          : this.dataEntrada,
      marcaModelo: data.marcaModelo.present
          ? data.marcaModelo.value
          : this.marcaModelo,
      imei: data.imei.present ? data.imei.value : this.imei,
      senhaDesbloqueio: data.senhaDesbloqueio.present
          ? data.senhaDesbloqueio.value
          : this.senhaDesbloqueio,
      checkDisplay: data.checkDisplay.present
          ? data.checkDisplay.value
          : this.checkDisplay,
      checkTouch: data.checkTouch.present
          ? data.checkTouch.value
          : this.checkTouch,
      problemaRelatado: data.problemaRelatado.present
          ? data.problemaRelatado.value
          : this.problemaRelatado,
      servicoExecutado: data.servicoExecutado.present
          ? data.servicoExecutado.value
          : this.servicoExecutado,
      valor: data.valor.present ? data.valor.value : this.valor,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OrdemDeServico(')
          ..write('id: $id, ')
          ..write('clienteId: $clienteId, ')
          ..write('tipoRegistro: $tipoRegistro, ')
          ..write('dataEntrada: $dataEntrada, ')
          ..write('marcaModelo: $marcaModelo, ')
          ..write('imei: $imei, ')
          ..write('senhaDesbloqueio: $senhaDesbloqueio, ')
          ..write('checkDisplay: $checkDisplay, ')
          ..write('checkTouch: $checkTouch, ')
          ..write('problemaRelatado: $problemaRelatado, ')
          ..write('servicoExecutado: $servicoExecutado, ')
          ..write('valor: $valor, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    clienteId,
    tipoRegistro,
    dataEntrada,
    marcaModelo,
    imei,
    senhaDesbloqueio,
    checkDisplay,
    checkTouch,
    problemaRelatado,
    servicoExecutado,
    valor,
    status,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OrdemDeServico &&
          other.id == this.id &&
          other.clienteId == this.clienteId &&
          other.tipoRegistro == this.tipoRegistro &&
          other.dataEntrada == this.dataEntrada &&
          other.marcaModelo == this.marcaModelo &&
          other.imei == this.imei &&
          other.senhaDesbloqueio == this.senhaDesbloqueio &&
          other.checkDisplay == this.checkDisplay &&
          other.checkTouch == this.checkTouch &&
          other.problemaRelatado == this.problemaRelatado &&
          other.servicoExecutado == this.servicoExecutado &&
          other.valor == this.valor &&
          other.status == this.status);
}

class OrdensServicoCompanion extends UpdateCompanion<OrdemDeServico> {
  final Value<int> id;
  final Value<int> clienteId;
  final Value<String> tipoRegistro;
  final Value<DateTime> dataEntrada;
  final Value<String> marcaModelo;
  final Value<String> imei;
  final Value<String> senhaDesbloqueio;
  final Value<bool> checkDisplay;
  final Value<bool> checkTouch;
  final Value<String> problemaRelatado;
  final Value<String?> servicoExecutado;
  final Value<double?> valor;
  final Value<String> status;
  const OrdensServicoCompanion({
    this.id = const Value.absent(),
    this.clienteId = const Value.absent(),
    this.tipoRegistro = const Value.absent(),
    this.dataEntrada = const Value.absent(),
    this.marcaModelo = const Value.absent(),
    this.imei = const Value.absent(),
    this.senhaDesbloqueio = const Value.absent(),
    this.checkDisplay = const Value.absent(),
    this.checkTouch = const Value.absent(),
    this.problemaRelatado = const Value.absent(),
    this.servicoExecutado = const Value.absent(),
    this.valor = const Value.absent(),
    this.status = const Value.absent(),
  });
  OrdensServicoCompanion.insert({
    this.id = const Value.absent(),
    required int clienteId,
    required String tipoRegistro,
    required DateTime dataEntrada,
    required String marcaModelo,
    required String imei,
    required String senhaDesbloqueio,
    this.checkDisplay = const Value.absent(),
    this.checkTouch = const Value.absent(),
    required String problemaRelatado,
    this.servicoExecutado = const Value.absent(),
    this.valor = const Value.absent(),
    this.status = const Value.absent(),
  }) : clienteId = Value(clienteId),
       tipoRegistro = Value(tipoRegistro),
       dataEntrada = Value(dataEntrada),
       marcaModelo = Value(marcaModelo),
       imei = Value(imei),
       senhaDesbloqueio = Value(senhaDesbloqueio),
       problemaRelatado = Value(problemaRelatado);
  static Insertable<OrdemDeServico> custom({
    Expression<int>? id,
    Expression<int>? clienteId,
    Expression<String>? tipoRegistro,
    Expression<DateTime>? dataEntrada,
    Expression<String>? marcaModelo,
    Expression<String>? imei,
    Expression<String>? senhaDesbloqueio,
    Expression<bool>? checkDisplay,
    Expression<bool>? checkTouch,
    Expression<String>? problemaRelatado,
    Expression<String>? servicoExecutado,
    Expression<double>? valor,
    Expression<String>? status,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (clienteId != null) 'cliente_id': clienteId,
      if (tipoRegistro != null) 'tipo_registro': tipoRegistro,
      if (dataEntrada != null) 'data_entrada': dataEntrada,
      if (marcaModelo != null) 'marca_modelo': marcaModelo,
      if (imei != null) 'imei': imei,
      if (senhaDesbloqueio != null) 'senha_desbloqueio': senhaDesbloqueio,
      if (checkDisplay != null) 'check_display': checkDisplay,
      if (checkTouch != null) 'check_touch': checkTouch,
      if (problemaRelatado != null) 'problema_relatado': problemaRelatado,
      if (servicoExecutado != null) 'servico_executado': servicoExecutado,
      if (valor != null) 'valor': valor,
      if (status != null) 'status': status,
    });
  }

  OrdensServicoCompanion copyWith({
    Value<int>? id,
    Value<int>? clienteId,
    Value<String>? tipoRegistro,
    Value<DateTime>? dataEntrada,
    Value<String>? marcaModelo,
    Value<String>? imei,
    Value<String>? senhaDesbloqueio,
    Value<bool>? checkDisplay,
    Value<bool>? checkTouch,
    Value<String>? problemaRelatado,
    Value<String?>? servicoExecutado,
    Value<double?>? valor,
    Value<String>? status,
  }) {
    return OrdensServicoCompanion(
      id: id ?? this.id,
      clienteId: clienteId ?? this.clienteId,
      tipoRegistro: tipoRegistro ?? this.tipoRegistro,
      dataEntrada: dataEntrada ?? this.dataEntrada,
      marcaModelo: marcaModelo ?? this.marcaModelo,
      imei: imei ?? this.imei,
      senhaDesbloqueio: senhaDesbloqueio ?? this.senhaDesbloqueio,
      checkDisplay: checkDisplay ?? this.checkDisplay,
      checkTouch: checkTouch ?? this.checkTouch,
      problemaRelatado: problemaRelatado ?? this.problemaRelatado,
      servicoExecutado: servicoExecutado ?? this.servicoExecutado,
      valor: valor ?? this.valor,
      status: status ?? this.status,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (clienteId.present) {
      map['cliente_id'] = Variable<int>(clienteId.value);
    }
    if (tipoRegistro.present) {
      map['tipo_registro'] = Variable<String>(tipoRegistro.value);
    }
    if (dataEntrada.present) {
      map['data_entrada'] = Variable<DateTime>(dataEntrada.value);
    }
    if (marcaModelo.present) {
      map['marca_modelo'] = Variable<String>(marcaModelo.value);
    }
    if (imei.present) {
      map['imei'] = Variable<String>(imei.value);
    }
    if (senhaDesbloqueio.present) {
      map['senha_desbloqueio'] = Variable<String>(senhaDesbloqueio.value);
    }
    if (checkDisplay.present) {
      map['check_display'] = Variable<bool>(checkDisplay.value);
    }
    if (checkTouch.present) {
      map['check_touch'] = Variable<bool>(checkTouch.value);
    }
    if (problemaRelatado.present) {
      map['problema_relatado'] = Variable<String>(problemaRelatado.value);
    }
    if (servicoExecutado.present) {
      map['servico_executado'] = Variable<String>(servicoExecutado.value);
    }
    if (valor.present) {
      map['valor'] = Variable<double>(valor.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OrdensServicoCompanion(')
          ..write('id: $id, ')
          ..write('clienteId: $clienteId, ')
          ..write('tipoRegistro: $tipoRegistro, ')
          ..write('dataEntrada: $dataEntrada, ')
          ..write('marcaModelo: $marcaModelo, ')
          ..write('imei: $imei, ')
          ..write('senhaDesbloqueio: $senhaDesbloqueio, ')
          ..write('checkDisplay: $checkDisplay, ')
          ..write('checkTouch: $checkTouch, ')
          ..write('problemaRelatado: $problemaRelatado, ')
          ..write('servicoExecutado: $servicoExecutado, ')
          ..write('valor: $valor, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ClientesTable clientes = $ClientesTable(this);
  late final $OrdensServicoTable ordensServico = $OrdensServicoTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [clientes, ordensServico];
}

typedef $$ClientesTableCreateCompanionBuilder =
    ClientesCompanion Function({
      Value<int> id,
      required String nome,
      required String telefone,
      required String cpf,
    });
typedef $$ClientesTableUpdateCompanionBuilder =
    ClientesCompanion Function({
      Value<int> id,
      Value<String> nome,
      Value<String> telefone,
      Value<String> cpf,
    });

final class $$ClientesTableReferences
    extends BaseReferences<_$AppDatabase, $ClientesTable, Cliente> {
  $$ClientesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$OrdensServicoTable, List<OrdemDeServico>>
  _ordensServicoRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.ordensServico,
    aliasName: $_aliasNameGenerator(db.clientes.id, db.ordensServico.clienteId),
  );

  $$OrdensServicoTableProcessedTableManager get ordensServicoRefs {
    final manager = $$OrdensServicoTableTableManager(
      $_db,
      $_db.ordensServico,
    ).filter((f) => f.clienteId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_ordensServicoRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ClientesTableFilterComposer
    extends Composer<_$AppDatabase, $ClientesTable> {
  $$ClientesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nome => $composableBuilder(
    column: $table.nome,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get telefone => $composableBuilder(
    column: $table.telefone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cpf => $composableBuilder(
    column: $table.cpf,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> ordensServicoRefs(
    Expression<bool> Function($$OrdensServicoTableFilterComposer f) f,
  ) {
    final $$OrdensServicoTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ordensServico,
      getReferencedColumn: (t) => t.clienteId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OrdensServicoTableFilterComposer(
            $db: $db,
            $table: $db.ordensServico,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ClientesTableOrderingComposer
    extends Composer<_$AppDatabase, $ClientesTable> {
  $$ClientesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nome => $composableBuilder(
    column: $table.nome,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get telefone => $composableBuilder(
    column: $table.telefone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cpf => $composableBuilder(
    column: $table.cpf,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ClientesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ClientesTable> {
  $$ClientesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nome =>
      $composableBuilder(column: $table.nome, builder: (column) => column);

  GeneratedColumn<String> get telefone =>
      $composableBuilder(column: $table.telefone, builder: (column) => column);

  GeneratedColumn<String> get cpf =>
      $composableBuilder(column: $table.cpf, builder: (column) => column);

  Expression<T> ordensServicoRefs<T extends Object>(
    Expression<T> Function($$OrdensServicoTableAnnotationComposer a) f,
  ) {
    final $$OrdensServicoTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ordensServico,
      getReferencedColumn: (t) => t.clienteId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OrdensServicoTableAnnotationComposer(
            $db: $db,
            $table: $db.ordensServico,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ClientesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ClientesTable,
          Cliente,
          $$ClientesTableFilterComposer,
          $$ClientesTableOrderingComposer,
          $$ClientesTableAnnotationComposer,
          $$ClientesTableCreateCompanionBuilder,
          $$ClientesTableUpdateCompanionBuilder,
          (Cliente, $$ClientesTableReferences),
          Cliente,
          PrefetchHooks Function({bool ordensServicoRefs})
        > {
  $$ClientesTableTableManager(_$AppDatabase db, $ClientesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ClientesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ClientesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ClientesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> nome = const Value.absent(),
                Value<String> telefone = const Value.absent(),
                Value<String> cpf = const Value.absent(),
              }) => ClientesCompanion(
                id: id,
                nome: nome,
                telefone: telefone,
                cpf: cpf,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String nome,
                required String telefone,
                required String cpf,
              }) => ClientesCompanion.insert(
                id: id,
                nome: nome,
                telefone: telefone,
                cpf: cpf,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ClientesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({ordensServicoRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (ordensServicoRefs) db.ordensServico,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (ordensServicoRefs)
                    await $_getPrefetchedData<
                      Cliente,
                      $ClientesTable,
                      OrdemDeServico
                    >(
                      currentTable: table,
                      referencedTable: $$ClientesTableReferences
                          ._ordensServicoRefsTable(db),
                      managerFromTypedResult: (p0) => $$ClientesTableReferences(
                        db,
                        table,
                        p0,
                      ).ordensServicoRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.clienteId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ClientesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ClientesTable,
      Cliente,
      $$ClientesTableFilterComposer,
      $$ClientesTableOrderingComposer,
      $$ClientesTableAnnotationComposer,
      $$ClientesTableCreateCompanionBuilder,
      $$ClientesTableUpdateCompanionBuilder,
      (Cliente, $$ClientesTableReferences),
      Cliente,
      PrefetchHooks Function({bool ordensServicoRefs})
    >;
typedef $$OrdensServicoTableCreateCompanionBuilder =
    OrdensServicoCompanion Function({
      Value<int> id,
      required int clienteId,
      required String tipoRegistro,
      required DateTime dataEntrada,
      required String marcaModelo,
      required String imei,
      required String senhaDesbloqueio,
      Value<bool> checkDisplay,
      Value<bool> checkTouch,
      required String problemaRelatado,
      Value<String?> servicoExecutado,
      Value<double?> valor,
      Value<String> status,
    });
typedef $$OrdensServicoTableUpdateCompanionBuilder =
    OrdensServicoCompanion Function({
      Value<int> id,
      Value<int> clienteId,
      Value<String> tipoRegistro,
      Value<DateTime> dataEntrada,
      Value<String> marcaModelo,
      Value<String> imei,
      Value<String> senhaDesbloqueio,
      Value<bool> checkDisplay,
      Value<bool> checkTouch,
      Value<String> problemaRelatado,
      Value<String?> servicoExecutado,
      Value<double?> valor,
      Value<String> status,
    });

final class $$OrdensServicoTableReferences
    extends BaseReferences<_$AppDatabase, $OrdensServicoTable, OrdemDeServico> {
  $$OrdensServicoTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ClientesTable _clienteIdTable(_$AppDatabase db) =>
      db.clientes.createAlias(
        $_aliasNameGenerator(db.ordensServico.clienteId, db.clientes.id),
      );

  $$ClientesTableProcessedTableManager get clienteId {
    final $_column = $_itemColumn<int>('cliente_id')!;

    final manager = $$ClientesTableTableManager(
      $_db,
      $_db.clientes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_clienteIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$OrdensServicoTableFilterComposer
    extends Composer<_$AppDatabase, $OrdensServicoTable> {
  $$OrdensServicoTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tipoRegistro => $composableBuilder(
    column: $table.tipoRegistro,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dataEntrada => $composableBuilder(
    column: $table.dataEntrada,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get marcaModelo => $composableBuilder(
    column: $table.marcaModelo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imei => $composableBuilder(
    column: $table.imei,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get senhaDesbloqueio => $composableBuilder(
    column: $table.senhaDesbloqueio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get checkDisplay => $composableBuilder(
    column: $table.checkDisplay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get checkTouch => $composableBuilder(
    column: $table.checkTouch,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get problemaRelatado => $composableBuilder(
    column: $table.problemaRelatado,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get servicoExecutado => $composableBuilder(
    column: $table.servicoExecutado,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get valor => $composableBuilder(
    column: $table.valor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  $$ClientesTableFilterComposer get clienteId {
    final $$ClientesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.clienteId,
      referencedTable: $db.clientes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClientesTableFilterComposer(
            $db: $db,
            $table: $db.clientes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$OrdensServicoTableOrderingComposer
    extends Composer<_$AppDatabase, $OrdensServicoTable> {
  $$OrdensServicoTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tipoRegistro => $composableBuilder(
    column: $table.tipoRegistro,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dataEntrada => $composableBuilder(
    column: $table.dataEntrada,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get marcaModelo => $composableBuilder(
    column: $table.marcaModelo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imei => $composableBuilder(
    column: $table.imei,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get senhaDesbloqueio => $composableBuilder(
    column: $table.senhaDesbloqueio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get checkDisplay => $composableBuilder(
    column: $table.checkDisplay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get checkTouch => $composableBuilder(
    column: $table.checkTouch,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get problemaRelatado => $composableBuilder(
    column: $table.problemaRelatado,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get servicoExecutado => $composableBuilder(
    column: $table.servicoExecutado,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get valor => $composableBuilder(
    column: $table.valor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  $$ClientesTableOrderingComposer get clienteId {
    final $$ClientesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.clienteId,
      referencedTable: $db.clientes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClientesTableOrderingComposer(
            $db: $db,
            $table: $db.clientes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$OrdensServicoTableAnnotationComposer
    extends Composer<_$AppDatabase, $OrdensServicoTable> {
  $$OrdensServicoTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get tipoRegistro => $composableBuilder(
    column: $table.tipoRegistro,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get dataEntrada => $composableBuilder(
    column: $table.dataEntrada,
    builder: (column) => column,
  );

  GeneratedColumn<String> get marcaModelo => $composableBuilder(
    column: $table.marcaModelo,
    builder: (column) => column,
  );

  GeneratedColumn<String> get imei =>
      $composableBuilder(column: $table.imei, builder: (column) => column);

  GeneratedColumn<String> get senhaDesbloqueio => $composableBuilder(
    column: $table.senhaDesbloqueio,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get checkDisplay => $composableBuilder(
    column: $table.checkDisplay,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get checkTouch => $composableBuilder(
    column: $table.checkTouch,
    builder: (column) => column,
  );

  GeneratedColumn<String> get problemaRelatado => $composableBuilder(
    column: $table.problemaRelatado,
    builder: (column) => column,
  );

  GeneratedColumn<String> get servicoExecutado => $composableBuilder(
    column: $table.servicoExecutado,
    builder: (column) => column,
  );

  GeneratedColumn<double> get valor =>
      $composableBuilder(column: $table.valor, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  $$ClientesTableAnnotationComposer get clienteId {
    final $$ClientesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.clienteId,
      referencedTable: $db.clientes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClientesTableAnnotationComposer(
            $db: $db,
            $table: $db.clientes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$OrdensServicoTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OrdensServicoTable,
          OrdemDeServico,
          $$OrdensServicoTableFilterComposer,
          $$OrdensServicoTableOrderingComposer,
          $$OrdensServicoTableAnnotationComposer,
          $$OrdensServicoTableCreateCompanionBuilder,
          $$OrdensServicoTableUpdateCompanionBuilder,
          (OrdemDeServico, $$OrdensServicoTableReferences),
          OrdemDeServico,
          PrefetchHooks Function({bool clienteId})
        > {
  $$OrdensServicoTableTableManager(_$AppDatabase db, $OrdensServicoTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OrdensServicoTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OrdensServicoTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OrdensServicoTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> clienteId = const Value.absent(),
                Value<String> tipoRegistro = const Value.absent(),
                Value<DateTime> dataEntrada = const Value.absent(),
                Value<String> marcaModelo = const Value.absent(),
                Value<String> imei = const Value.absent(),
                Value<String> senhaDesbloqueio = const Value.absent(),
                Value<bool> checkDisplay = const Value.absent(),
                Value<bool> checkTouch = const Value.absent(),
                Value<String> problemaRelatado = const Value.absent(),
                Value<String?> servicoExecutado = const Value.absent(),
                Value<double?> valor = const Value.absent(),
                Value<String> status = const Value.absent(),
              }) => OrdensServicoCompanion(
                id: id,
                clienteId: clienteId,
                tipoRegistro: tipoRegistro,
                dataEntrada: dataEntrada,
                marcaModelo: marcaModelo,
                imei: imei,
                senhaDesbloqueio: senhaDesbloqueio,
                checkDisplay: checkDisplay,
                checkTouch: checkTouch,
                problemaRelatado: problemaRelatado,
                servicoExecutado: servicoExecutado,
                valor: valor,
                status: status,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int clienteId,
                required String tipoRegistro,
                required DateTime dataEntrada,
                required String marcaModelo,
                required String imei,
                required String senhaDesbloqueio,
                Value<bool> checkDisplay = const Value.absent(),
                Value<bool> checkTouch = const Value.absent(),
                required String problemaRelatado,
                Value<String?> servicoExecutado = const Value.absent(),
                Value<double?> valor = const Value.absent(),
                Value<String> status = const Value.absent(),
              }) => OrdensServicoCompanion.insert(
                id: id,
                clienteId: clienteId,
                tipoRegistro: tipoRegistro,
                dataEntrada: dataEntrada,
                marcaModelo: marcaModelo,
                imei: imei,
                senhaDesbloqueio: senhaDesbloqueio,
                checkDisplay: checkDisplay,
                checkTouch: checkTouch,
                problemaRelatado: problemaRelatado,
                servicoExecutado: servicoExecutado,
                valor: valor,
                status: status,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$OrdensServicoTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({clienteId = false}) {
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
                    if (clienteId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.clienteId,
                                referencedTable: $$OrdensServicoTableReferences
                                    ._clienteIdTable(db),
                                referencedColumn: $$OrdensServicoTableReferences
                                    ._clienteIdTable(db)
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

typedef $$OrdensServicoTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OrdensServicoTable,
      OrdemDeServico,
      $$OrdensServicoTableFilterComposer,
      $$OrdensServicoTableOrderingComposer,
      $$OrdensServicoTableAnnotationComposer,
      $$OrdensServicoTableCreateCompanionBuilder,
      $$OrdensServicoTableUpdateCompanionBuilder,
      (OrdemDeServico, $$OrdensServicoTableReferences),
      OrdemDeServico,
      PrefetchHooks Function({bool clienteId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ClientesTableTableManager get clientes =>
      $$ClientesTableTableManager(_db, _db.clientes);
  $$OrdensServicoTableTableManager get ordensServico =>
      $$OrdensServicoTableTableManager(_db, _db.ordensServico);
}
