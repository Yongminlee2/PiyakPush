/// 격자 좌표와 4방향. 엔진 전역에서 사용하는 최소 기하 타입.
library;

enum Dir { up, down, left, right }

class Point {
  final int x, y;
  const Point(this.x, this.y);

  Point step(Dir d) => switch (d) {
        Dir.up => Point(x, y - 1),
        Dir.down => Point(x, y + 1),
        Dir.left => Point(x - 1, y),
        Dir.right => Point(x + 1, y),
      };

  @override
  bool operator ==(Object other) =>
      other is Point && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => '($x,$y)';
}
