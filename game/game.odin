package game

import "../audio"
import "../cull"
import "../input"
import "../lod"
import obj "../object"
import "../perf"
import "../player"
import "../render"
import "../scene"
import "../dynamics"
import "../state"
import "../stress"
import "../ui"
import "core:fmt"
import "core:math/linalg"
import "core:time"
import rl "vendor:raylib"

SPIN_SPEED :: 1.2
CAMERA_FOV :: 45.0
PERF_CSV :: "perf.csv"
JUMP_BEEP_HZ :: 660.0
JUMP_BEEP_SECS :: 0.12
CAMERA_OFFSET :: linalg.Vector3f32{9, 8, 9}
GROUND_SIZE :: f32(200)
GAME_TITLE :: "ODIN ENGINE"
MENU_LINES := [2]string{"WASD to move, SPACE to jump, P to pause", "press ENTER to start"}
PAUSE_HINT :: "press P to resume"

Game :: struct {
	scene:      scene.Scene,
	camera:     rl.Camera3D,
	angle:      f32,
	meter:      perf.Meter,
	frame:      int,
	culling:    bool,
	instancing: bool,
	drawn:      int,
	draw_calls: int,
	culled:     int,
	assets_ok:  bool,
	cube_mesh:  rl.Mesh,
	cube_mat:   rl.Material,
	gltf_model: rl.Model,
	jump_beep:  rl.Sound,
	bus:        audio.Audio_Bus,
	machine:    state.Machine,
	actions:    input.Action_Map,
	hero:       player.Player,
	phys:       dynamics.Physics,
	contacts:   int,
}

make_game :: proc(stress_count: int, seed: u64, culling, instancing: bool) -> Game {
	g := Game {
		scene = scene.make_scene(),
		camera = rl.Camera3D {
			position = {60, 40, 60},
			target = {0, 2, 0},
			up = {0, 1, 0},
			fovy = CAMERA_FOV,
			projection = .PERSPECTIVE,
		},
		meter = perf.make_meter(),
		culling = culling,
		instancing = instancing,
		bus = audio.make_bus(),
		machine = state.make_machine(),
		actions = input.make_action_map(),
		hero = player.make_player({0, player.HALF_HEIGHT, 0}),
	}
	if stress_count > 0 {
		stress.generate(&g.scene, stress_count, seed)
	} else {
		box := scene.spawn(&g.scene, "box")
		obj.set_mesh(box, obj.Mesh_Component{color = rl.DARKBLUE, size = {1, 1, 1}})
		obj.set_health(box, obj.Health_Component{current = 100, max = 100})
		box.body = obj.Rigid_Body {
			velocity = {0, 0, 0},
			mass     = 1,
		}
		box.collider = obj.Collider {
			half_extents = {0.5, 0.5, 0.5},
		}
	}
	ground := scene.spawn(&g.scene, "ground")
	ground.transform.position = {0, -0.6, 0}
	ground.collider = obj.Collider {
		half_extents = {100, 0.5, 100},
	}
	g.phys = dynamics.build(&g.scene, {0, -9.81, 0})
	return g
}

destroy_game :: proc(g: ^Game) {
	input.destroy_action_map(&g.actions)
	perf.destroy_meter(&g.meter)
	dynamics.destroy(&g.phys)
	scene.destroy_scene(&g.scene)
	if g.assets_ok {
		rl.CloseAudioDevice()
	}
}

ensure_assets :: proc(g: ^Game) {
	if g.assets_ok {
		return
	}
	g.cube_mesh = rl.GenMeshCube(1, 1, 1)
	g.cube_mat = rl.LoadMaterialDefault()
	g.gltf_model = rl.LoadModel("assets/models/triangle.gltf")
	rl.InitAudioDevice()
	frames := audio.sine_frames(JUMP_BEEP_HZ, JUMP_BEEP_SECS, context.temp_allocator)
	wave := rl.Wave {
		frameCount = u32(len(frames)),
		sampleRate = audio.SAMPLE_RATE,
		sampleSize = 32,
		channels   = 1,
		data       = raw_data(frames),
	}
	g.jump_beep = rl.LoadSoundFromWave(wave)
	rl.SetSoundVolume(g.jump_beep, audio.mix_gain(&g.bus, .Sfx))
	g.assets_ok = true
}

move_input :: proc(g: ^Game, keys: input.Key_State) -> linalg.Vector2f32 {
	move := linalg.Vector2f32{0, 0}
	if input.action_down(&g.actions, keys, .Move_Forward) {
		move.y -= 1
	}
	if input.action_down(&g.actions, keys, .Move_Back) {
		move.y += 1
	}
	if input.action_down(&g.actions, keys, .Move_Left) {
		move.x -= 1
	}
	if input.action_down(&g.actions, keys, .Move_Right) {
		move.x += 1
	}
	if linalg.length(move) > 1 {
		move = linalg.normalize(move)
	}
	return move
}

update :: proc(g: ^Game, dt: f32) {
	start := time.tick_now()
	if g.machine.current == .Menu {
		if rl.IsKeyPressed(.ENTER) {
			state.to_playing(&g.machine)
		}
		g.meter.update_ms = time.duration_milliseconds(time.tick_since(start))
		return
	}
	if rl.IsKeyPressed(.P) || rl.IsKeyPressed(.ESCAPE) {
		state.toggle_pause(&g.machine)
	}
	if g.machine.current != .Playing {
		g.meter.update_ms = time.duration_milliseconds(time.tick_since(start))
		return
	}
	keys := input.poll_live_state()
	defer delete(keys)
	move := move_input(g, keys)
	jump := input.action_down(&g.actions, keys, .Jump) && g.hero.grounded
	if player.step(&g.hero, move, jump, dt) && g.assets_ok {
		rl.PlaySound(g.jump_beep)
	}
	g.camera.target = g.hero.position
	g.camera.position = g.hero.position + CAMERA_OFFSET
	g.angle += SPIN_SPEED * dt
	contacts := dynamics.step(&g.phys, &g.scene, dt)
	g.contacts = len(contacts)
	delete(contacts)
	g.meter.update_ms = time.duration_milliseconds(time.tick_since(start))
}

bounding_radius :: proc(o: ^obj.Game_Object) -> f32 {
	m, ok := o.mesh.?
	if !ok {
		return 1
	}
	return linalg.length(m.size) / 2
}

visible_objects :: proc(g: ^Game, allocator := context.allocator) -> []^obj.Game_Object {
	list := make([dynamic]^obj.Game_Object, allocator)
	if !g.culling {
		for &o in g.scene.objects {
			if o.active {
				append(&list, &o)
			}
		}
		return list[:]
	}
	aspect := f32(rl.GetScreenWidth()) / f32(max(rl.GetScreenHeight(), 1))
	f := cull.from_camera(g.camera, aspect)
	for &o in g.scene.objects {
		if !o.active {
			continue
		}
		if cull.sphere_visible(f, o.transform.position, bounding_radius(&o)) {
			append(&list, &o)
		} else {
			g.culled += 1
		}
	}
	return list[:]
}

draw_shape :: proc(g: ^Game, o: ^obj.Game_Object) {
	m, ok := o.mesh.?
	if !ok {
		return
	}
	dist := linalg.distance(g.camera.position, o.transform.position)
	level := lod.select(dist)
	#partial switch m.shape {
	case .Box:
		// boxes can rotate now, so draw them with the whole matrix.
		mat := g.cube_mat
		mat.maps[rl.MaterialMapIndex.ALBEDO].color = m.color
		w, wok := scene.world_matrix(&g.scene, o.id)
		if !wok {
			w = obj.local_matrix(o.transform)
		}
		rl.DrawMesh(g.cube_mesh, mat, transmute(rl.Matrix)w)
		g.draw_calls += 1
	case .Sphere:
		if level == .Full {
			rl.DrawSphereEx(o.transform.position, m.size.x / 2, 12, 12, m.color)
		} else {
			rl.DrawCube(o.transform.position, m.size.x, m.size.y, m.size.z, m.color)
		}
		g.draw_calls += 1
	case .Gltf:
		if level == .Full && g.assets_ok {
			rl.DrawModel(g.gltf_model, o.transform.position, m.size.x, m.color)
		} else {
			rl.DrawCube(o.transform.position, m.size.x, m.size.y, m.size.z, m.color)
		}
		g.draw_calls += 1
	}
}

draw :: proc(g: ^Game, alpha: f32) {
	_ = alpha
	start := time.tick_now()
	ensure_assets(g)
	g.drawn = 0
	g.draw_calls = 0
	g.culled = 0
	rl.ClearBackground(rl.RAYWHITE)
	rl.BeginMode3D(g.camera)
	rl.DrawCube({0, -0.05, 0}, GROUND_SIZE, 0.1, GROUND_SIZE, rl.LIGHTGRAY)
	rl.DrawCube(g.hero.position, 0.8, 1.0, 0.8, rl.MAROON)
	g.draw_calls += 1
	g.drawn += 1
	visible := visible_objects(g, context.temp_allocator)
	if g.instancing {
		batches := render.collect_boxes(visible, context.temp_allocator)
		defer render.destroy_batches(&batches)
		for key, list in batches {
			mat := g.cube_mat
			mat.maps[rl.MaterialMapIndex.ALBEDO].color = key.color
			rl.DrawMeshInstanced(g.cube_mesh, mat, raw_data(list), i32(len(list)))
			g.draw_calls += 1
			g.drawn += len(list)
		}
		for o in visible {
			m, ok := o.mesh.?
			if ok && m.shape != .Box {
				draw_shape(g, o)
				g.drawn += 1
			}
		}
	} else {
		for o in visible {
			draw_shape(g, o)
			g.drawn += 1
		}
	}
	rl.EndMode3D()
	g.meter.draw_ms = time.duration_milliseconds(time.tick_since(start))
	perf.push_frame(&g.meter, rl.GetFrameTime())
	if g.frame % 30 == 0 {
		perf.record_row(&g.meter, g.frame)
	}
	if g.frame % 60 == 0 {
		perf.reset_worst(&g.meter)
	}
	g.frame += 1
	stats := ui.stats_text(
		f64(perf.avg_fps(&g.meter)),
		f64(g.meter.worst * 1000),
		g.meter.update_ms,
		g.meter.draw_ms,
		g.drawn,
		len(g.scene.objects),
		g.draw_calls,
		g.culled,
		context.temp_allocator,
	)
	rl.DrawText(fmt.ctprintf("%s", stats), 10, 10, 20, rl.DARKGRAY)
	if g.machine.current == .Menu {
		ui.title_screen(GAME_TITLE, MENU_LINES[:])
	} else if g.machine.current == .Paused {
		ui.pause_overlay(PAUSE_HINT)
	}
}
