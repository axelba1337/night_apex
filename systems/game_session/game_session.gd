extends Node

enum GameMode { SPRINT, SPEED_TRAP }
enum RouteId { ROUTE_01, ROUTE_02 }

var selected_mode: GameMode = GameMode.SPRINT
var selected_route: RouteId = RouteId.ROUTE_01
var best_sprint_time: float = 0.0
var best_speed_trap_speed: float = 0.0
