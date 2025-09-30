/// Parâmetros para busca combinada de usuários
class SearchParameters {
  final String? nameQuery;
  final String? gender;
  final String? emailQuery;
  final int? minAge;
  final int? maxAge;
  final int limit;
  final bool caseInsensitive;

  const SearchParameters({
    this.nameQuery,
    this.gender,
    this.emailQuery,
    this.minAge,
    this.maxAge,
    this.limit = 10,
    this.caseInsensitive = true,
  });

  /// Cria uma cópia com novos valores
  SearchParameters copyWith({
    String? nameQuery,
    String? gender,
    String? emailQuery,
    int? minAge,
    int? maxAge,
    int? limit,
    bool? caseInsensitive,
  }) {
    return SearchParameters(
      nameQuery: nameQuery ?? this.nameQuery,
      gender: gender ?? this.gender,
      emailQuery: emailQuery ?? this.emailQuery,
      minAge: minAge ?? this.minAge,
      maxAge: maxAge ?? this.maxAge,
      limit: limit ?? this.limit,
      caseInsensitive: caseInsensitive ?? this.caseInsensitive,
    );
  }

  /// Verifica se há algum parâmetro de busca definido
  bool get hasSearchCriteria {
    return nameQuery?.isNotEmpty == true ||
        gender?.isNotEmpty == true ||
        emailQuery?.isNotEmpty == true ||
        minAge != null ||
        maxAge != null;
  }

  /// Retorna uma descrição dos critérios de busca
  String get searchDescription {
    final criteria = <String>[];
    
    if (nameQuery?.isNotEmpty == true) {
      criteria.add('nome contém "$nameQuery"');
    }
    if (gender?.isNotEmpty == true) {
      criteria.add('gênero = $gender');
    }
    if (emailQuery?.isNotEmpty == true) {
      criteria.add('email contém "$emailQuery"');
    }
    if (minAge != null) {
      criteria.add('idade >= $minAge');
    }
    if (maxAge != null) {
      criteria.add('idade <= $maxAge');
    }
    
    return criteria.isEmpty ? 'Todos os usuários' : criteria.join(' e ');
  }
}
