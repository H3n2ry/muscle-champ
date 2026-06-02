class ExerciseLibrary {
  ExerciseLibrary._();

  static const Map<String, List<String>> byGroup = {
    'Peito': [
      'Supino Reto',
      'Supino Inclinado',
      'Supino Declinado',
      'Supino com Halteres',
      'Crossover',
      'Fly com Halteres',
      'Peck Deck',
      'Flexão de Braços',
      'Pullover',
    ],
    'Costas': [
      'Puxada Frontal',
      'Puxada Neutra',
      'Remada Curvada',
      'Remada Unilateral',
      'Remada Baixa',
      'Levantamento Terra',
      'Pull-up',
      'Chin-up',
      'Serrote',
      'Remada na Máquina',
    ],
    'Ombros': [
      'Desenvolvimento com Halteres',
      'Desenvolvimento Arnold',
      'Desenvolvimento na Máquina',
      'Elevação Lateral',
      'Elevação Frontal',
      'Remada Alta',
      'Face Pull',
      'Rotação Externa',
    ],
    'Bíceps': [
      'Rosca Direta',
      'Rosca Alternada',
      'Rosca Martelo',
      'Rosca Concentrada',
      'Rosca Scott',
      'Rosca na Polia',
      'Rosca 21',
    ],
    'Tríceps': [
      'Tríceps Corda',
      'Tríceps Testa',
      'Tríceps Francês',
      'Tríceps Banco',
      'Tríceps Coice',
      'Tríceps na Polia Alta',
      'Mergulho no Banco',
      'Close Grip Press',
    ],
    'Pernas': [
      'Agachamento Livre',
      'Agachamento no Smith',
      'Leg Press 45°',
      'Cadeira Extensora',
      'Cadeira Flexora',
      'Stiff',
      'Afundo',
      'Avanço com Halteres',
      'Panturrilha em Pé',
      'Panturrilha Sentado',
      'Leg Press (panturrilha)',
    ],
    'Glúteos': [
      'Hip Thrust',
      'Hip Thrust Unilateral',
      'Glúteo na Polia',
      'Abdução no Cabo',
      'Cadeira Abdutora',
      'Elevação Pélvica',
      'Afundo Lateral',
    ],
    'Core': [
      'Prancha',
      'Prancha Lateral',
      'Crunch',
      'Crunch Inverso',
      'Abdominal Bicicleta',
      'Russian Twist',
      'Elevação de Pernas',
      'Rollout com Roda',
      'Abdominal no Cabo',
      'Dead Bug',
    ],
  };

  static List<String> get allGroups => byGroup.keys.toList();

  static List<String> search(String query) {
    if (query.trim().isEmpty) return [];
    final q = query.toLowerCase();
    return byGroup.values
        .expand((list) => list)
        .where((name) => name.toLowerCase().contains(q))
        .toList();
  }
}
