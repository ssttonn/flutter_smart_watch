class Node {
  final String id;
  final String name;
  final bool isNearby;

  Node({required this.id, required this.name, required this.isNearby});

  factory Node.fromJson(Map<String, dynamic> json) => Node(
      id: json["id"] as String? ?? "",
      name: json["name"] as String? ?? "",
      isNearby: json["isNearby"] as bool? ?? false);
}
