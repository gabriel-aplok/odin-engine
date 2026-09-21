package game

import "../assets"
import "../audio"
import "../config"
import "../cull"
import "../dynamics"
import "../editor"
import "../events"
import "../input"
import "../lod"
import "../material"
import mem "../memory"
import obj "../object"
import "../perf"
import "../player"
import "../render"
import "../scene"
import "../state"
import "../stream"
import "../stress"
import "../ui"
import "core:fmt"
import "core:math/linalg"
import "core:time"
import "base:runtime"
import rl "vendor:raylib"

SPIN_SPEED :: 1.2
CAMERA_FOV :: 45.0
PERF_CSV :: "perf.csv"
JUMP_BEEP_HZ :: 660.0
JUMP_BEEP_SECS :: 0.12
GROUND_SIZE :: f32(200)
GAME_TITLE :: "ODIN ENGINE"
MENU_LINES := [2]string{
	"WASD to move, SPACE to jump, P to pause",
	"press ENTER to start",
}
PAUSE_TITLE :: "PAUSED"
PAUSE_HINT :: "press P to resume"
MODEL_PATH :: "assets/models/triangle.gltf"
VS_PATH :: "assets/shaders/lit.vs"
FS_PATH :: "assets/shaders/lit.fs"
LIGHT_DIR := [3]f32{-0.5, -1, -0.3}
// our words. the engine names none of these.
MENU :: "menu"
PLAYING :: "playing"
PAUSED :: "paused"
ACTION_FORWARD :: "move_forward"
ACTION_BACK :: "move_back"
ACTION_LEFT :: "move_left"
ACTION_RIGHT :: "move_right"
ACTION_JUMP :: "jump"
TOPIC_CONTACT :: "contact"
TOPIC_JUMP :: "jump"

// handlers get the game pointer back through ctx. no globals.
on_contact :: proc(e: events.Event, ctx: rawptr) {
	g := (^Game)(ctx)
	g.contact_tally += 1
}

on_jump :: proc(e: events.Event, ctx: rawptr) {
	g := (^Game)(ctx)
	if g.beep_ready {
		rl.PlaySound(g.beep)
	}
}

Game :: struct {
	cfg:        config.Config,
	scene:      scene.Scene,
	camera:     rl.Camera3D,
	angle:      f32,
	meter:      perf.Meter,
	frame:      int,
	drawn:      int,
	draw_calls: int,
	culled:     int,
	assets_ok:  bool,
	cube_mesh:  rl.Mesh,
	cube_mat:   rl.Material,
	gltf_model: rl.Model,
	model_handle: assets.Asset_Handle,
	model_ready: bool,
	bus:        audio.Audio_Bus,
	topic:      events.Bus,
	machine:    state.Machine,
	actions:    input.Action_Map,
	hero:       player.Player,
	phys:       dynamics.Physics,
	contacts:   int,
	contact_tally: int,
	beep:       rl.Sound,
	beep_ready: bool,
	edcam:      editor.Editor_Camera,
	scratch:    mem.Frame,
	store:      assets.Asset_Store,
	streamer:   stream.Streamer,
	lit:        material.Material,
}

make_game :: proc(cfg: config.Config) -> Game {
	g := Game {
		cfg = cfg,
		scene = scene.make_scene(),
		camera = rl.Camera3D {
			position = {60, 40, 60},
			target = {0, 2, 0},
			up = {0, 1, 0},
			fovy = CAMERA_FOV,
			projection = .PERSPECTIVE,
		},
		meter = perf.make_meter(),
		bus = audio.make_bus(),
		topic = events.make_bus(),
		machine = state.make_machine(),
		actions = input.make_action_map(),
		hero = player.make_player({0, player.HALF_HEIGHT, 0}),
		edcam = editor.Editor_Camera{yaw = 0.7, pitch = 0.45, distance = 14},
		scratch = mem.make_frame(cfg.frame_budget),
		store = assets.make_store(),
		streamer = stream.make_streamer(cfg.stream_budget),
	}
	audio.set_gain(&g.bus, .Master, cfg.master_gain)
	audio.set_gain(&g.bus, .Music, cfg.music_gain)
	audio.set_gain(&g.bus, .Sfx, cfg.sfx_gain)
	input.bind_key(&g.actions, ACTION_FORWARD, rl.KeyboardKey.W)
	input.bind_key(&g.actions, ACTION_FORWARD, rl.KeyboardKey.UP)
	input.bind_key(&g.actions, ACTION_BACK, rl.KeyboardKey.S)
	input.bind_key(&g.actions, ACTION_BACK, rl.KeyboardKey.DOWN)
	input.bind_key(&g.actions, ACTION_LEFT, rl.KeyboardKey.A)
	input.bind_key(&g.actions, ACTION_LEFT, rl.KeyboardKey.LEFT)
	input.bind_key(&g.actions, ACTION_RIGHT, rl.KeyboardKey.D)
	input.bind_key(&g.actions, ACTION_RIGHT, rl.KeyboardKey.RIGHT)
	input.bind_key(&g.actions, ACTION_JUMP, rl.KeyboardKey.SPACE)
	input.bind_pad(&g.actions, ACTION_JUMP, rl.GamepadButton.RIGHT_FACE_DOWN)
	state.set(&g.machine, MENU)
	if cfg.stress_count > 0 {
		stress.generate(&g.scene, cfg.stress_count, cfg.seed)
	} else {
		box := scene.spawn(&g.scene, "box")
		box.transform.position = {-4, 4, 3}
		obj.set_mesh(box, obj.Mesh_Component{color = rl.DARKBLUE, size = {1, 1, 1}})
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

// call once the game sits where it will live. handlers keep the
// pointer, so subscribing a copy would dangle.
connect_events :: proc(g: ^Game) {
	events.subscribe(&g.topic, TOPIC_CONTACT, on_contact, g)
	events.subscribe(&g.topic, TOPIC_JUMP, on_jump, g)
}

destroy_game :: proc(g: ^Game) {
	material.unload_material(&g.lit)
	assets.destroy_store(&g.store)
	stream.destroy_streamer(&g.streamer)
	events.destroy_bus(&g.topic)
	mem.destroy_frame(&g.scratch)
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
	// model bytes go through the store and the streamer queue,
	// the gpu upload only happens once the streamer says loaded.
	model_handle, ok := assets.load_file(&g.store, MODEL_PATH, .Bytes)
	if ok {
		g.model_handle = model_handle
	}
	if material.load_lit_material(&g.lit, &g.store, VS_PATH, FS_PATH, rl.WHITE) {
		dir_loc := rl.GetShaderLocation(g.lit.shader, "lightDir")
		rl.SetShaderValue(g.lit.shader, dir_loc, &LIGHT_DIR, .VEC3)
		// defaults are zero, which means invisible. white keeps colors as drawn.
		white := [4]f32{1, 1, 1, 1}
		tint_loc := rl.GetShaderLocation(g.lit.shader, "tint")
		rl.SetShaderValue(g.lit.shader, tint_loc, &white, .VEC4)
	}
	rl.InitAudioDevice()
	frames := audio.sine_frames(JUMP_BEEP_HZ, JUMP_BEEP_SECS, context.temp_allocator)
	wave := rl.Wave {
		frameCount = u32(len(frames)),
		sampleRate = audio.SAMPLE_RATE,
		sampleSize = 32,
		channels   = 1,
		data       = raw_data(frames),
	}
	g.beep = rl.LoadSoundFromWave(wave)
	g.beep_ready = true
	rl.SetSoundVolume(g.beep, audio.mix_gain(&g.bus, .Sfx))
	g.assets_ok = true
}

move_input :: proc(g: ^Game, keys: input.Input_State) -> linalg.Vector2f32 {
	move := linalg.Vector2f32{0, 0}
	if input.action_down(&g.actions, keys, ACTION_FORWARD) {
		move.y -= 1
	}
	if input.action_down(&g.actions, keys, ACTION_BACK) {
		move.y += 1
	}
	if input.action_down(&g.actions, keys, ACTION_LEFT) {
		move.x -= 1
	}
	if input.action_down(&g.actions, keys, ACTION_RIGHT) {
		move.x += 1
	}
	if linalg.length(move) > 1 {
		move = linalg.normalize(move)
	}
	return move
}

update :: proc(g: ^Game, dt: f32) {
	frame_tick := perf.zone_begin()
	defer perf.zone_end(&g.meter, "frame", frame_tick)
	if state.is(&g.machine, MENU) {
		if rl.IsKeyPressed(.ENTER) {
			state.set(&g.machine, PLAYING)
		}
		g.meter.update_ms = time.duration_milliseconds(time.tick_since(frame_tick))
		return
	}
	if rl.IsKeyPressed(.P) || rl.IsKeyPressed(.ESCAPE) {
		if state.is(&g.machine, PLAYING) {
			state.set(&g.machine, PAUSED)
		} else if state.is(&g.machine, PAUSED) {
			state.set(&g.machine, PLAYING)
		}
	}
	if !state.is(&g.machine, PLAYING) {
		g.meter.update_ms = time.duration_milliseconds(time.tick_since(frame_tick))
		return
	}
	g.contact_tally = 0
	input_tick := perf.zone_begin()
	keys := input.poll_live_state()
	defer input.destroy_input_state(&keys)
	move := move_input(g, keys)
	jump := input.action_down(&g.actions, keys, ACTION_JUMP) && g.hero.grounded
	perf.zone_end(&g.meter, "input", input_tick)
	player_tick := perf.zone_begin()
	if player.step(&g.hero, move, jump, dt) {
		events.emit(&g.topic, TOPIC_JUMP)
	}
	perf.zone_end(&g.meter, "player", player_tick)
	g.camera.target = g.hero.position
	// hold right mouse to look around, wheel zooms.
	if rl.IsMouseButtonDown(.RIGHT) {
		delta := rl.GetMouseDelta()
		editor.orbit(&g.edcam, delta.x, -delta.y)
	}
	wheel := rl.GetMouseWheelMove()
	if wheel != 0 {
		editor.zoom(&g.edcam, -wheel)
	}
	g.edcam.target = g.hero.position
	g.camera.position = editor.camera_position(g.edcam)
	g.angle += SPIN_SPEED * dt
	sim_tick := perf.zone_begin()
	contacts := dynamics.step(&g.phys, &g.scene, dt)
	for c in contacts {
		events.emit(&g.topic, TOPIC_CONTACT, c.a, c.b)
	}
	delete(contacts)
	perf.zone_end(&g.meter, "sim", sim_tick)
	events.poll(&g.topic)
	g.contacts = g.contact_tally
	g.meter.update_ms = time.duration_milliseconds(time.tick_since(frame_tick))
}

bounding_radius :: proc(o: ^obj.Game_Object) -> f32 {
	m, ok := o.mesh.?
	if !ok {
		return 1
	}
	return linalg.length(m.size) / 2
}

visible_objects :: proc(g: ^Game, alpha: f32, allocator := context.allocator) -> []^obj.Game_Object {
	list := make([dynamic]^obj.Game_Object, allocator)
	if !g.cfg.culling {
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
		if cull.sphere_visible(f, obj.interp_position(o.transform, alpha), bounding_radius(&o)) {
			append(&list, &o)
		} else {
			g.culled += 1
		}
	}
	return list[:]
}

draw_shape :: proc(g: ^Game, o: ^obj.Game_Object, alpha: f32) {
	m, ok := o.mesh.?
	if !ok {
		return
	}
	spot := obj.interp_position(o.transform, alpha)
	dist := linalg.distance(g.camera.position, spot)
	level := lod.select(dist)
	#partial switch m.shape {
	case .Box:
		// boxes can rotate now, so draw them with the whole matrix.
		mat := g.cube_mat
		mat.maps[rl.MaterialMapIndex.ALBEDO].color = m.color
		t := o.transform
		t.position = spot
		w := obj.local_matrix(t)
		if pw, ok := scene.world_matrix(&g.scene, o.id); ok {
			// keep the parent rotation and scale, use the between spot.
			w = pw
			w[3][0] = spot.x
			w[3][1] = spot.y
			w[3][2] = spot.z
		}
		rl.DrawMesh(g.cube_mesh, mat, transmute(rl.Matrix)w)
		g.draw_calls += 1
	case .Sphere:
		if level == .Full {
			rl.DrawSphereEx(spot, m.size.x / 2, 12, 12, m.color)
		} else {
			rl.DrawCube(spot, m.size.x, m.size.y, m.size.z, m.color)
		}
		g.draw_calls += 1
	case .Gltf:
		if level == .Full && g.model_ready {
			rl.DrawModel(g.gltf_model, spot, m.size.x, m.color)
		} else {
			rl.DrawCube(spot, m.size.x, m.size.y, m.size.z, m.color)
		}
		g.draw_calls += 1
	}
}

draw :: proc(g: ^Game, alpha: f32) {
	start := time.tick_now()
	ensure_assets(g)
	mem.reset(&g.scratch)
	frame_alloc := mem.allocator(&g.scratch)
	g.drawn = 0
	g.draw_calls = 0
	g.culled = 0
	rl.ClearBackground(rl.RAYWHITE)
	rl.BeginMode3D(g.camera)
	draw_world(g, alpha, frame_alloc)
	draw_debug(g)
	rl.EndMode3D()
// lit pass. floor, hero, and every object go through the game shader.
draw_world :: proc(g: ^Game, alpha: f32, frame_alloc: runtime.Allocator) {
	if g.lit.loaded {
		rl.BeginShaderMode(g.lit.shader)
	}
	defer if g.lit.loaded {
		rl.EndShaderMode()
	}
	rl.DrawCube({0, -0.05, 0}, GROUND_SIZE, 0.1, GROUND_SIZE, rl.LIGHTGRAY)
	hero_spot := g.hero.prev_position + (g.hero.position - g.hero.prev_position) * alpha
	rl.DrawCube(hero_spot, 0.8, 1.0, 0.8, rl.MAROON)
	g.draw_calls += 1
	g.drawn += 1
	// the streamer owns the model file. boxes draw until it says loaded.
	if !g.model_ready {
		if asset, ok := assets.get(&g.store, g.model_handle); ok {
			stream.request(&g.streamer, MODEL_PATH, len(asset.data), g.frame)
		}
		stream.pump(&g.streamer)
		if _, ok := g.streamer.loaded[MODEL_PATH]; ok {
			g.gltf_model = rl.LoadModel(MODEL_PATH)
			g.model_ready = true
		}
	}
	cull_tick := perf.zone_begin()
	visible := visible_objects(g, alpha, frame_alloc)
	perf.zone_end(&g.meter, "cull", cull_tick)
	batch_tick := perf.zone_begin()
	defer perf.zone_end(&g.meter, "batch", batch_tick)
	if g.cfg.instancing {
		batches := render.collect_boxes(visible, alpha, frame_alloc)
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
				draw_shape(g, o, alpha)
				g.drawn += 1
			}
		}
	} else {
		for o in visible {
			draw_shape(g, o, alpha)
			g.drawn += 1
		}
	}
}

// debug pass. plain lines need no shader, so this runs without one.
draw_debug :: proc(g: ^Game) {
	_ = g
	rl.DrawGrid(40, 5)
}
	g.meter.draw_ms = time.duration_milliseconds(time.tick_since(start))
	perf.push_frame(&g.meter, rl.GetFrameTime())
	if g.frame % 30 == 0 {
		perf.record_row(&g.meter, g.frame)
	}
	if g.frame % 60 == 0 {
		perf.reset_worst(&g.meter)
		perf.zone_reset(&g.meter)
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
	slow := perf.priciest_zone(&g.meter, context.temp_allocator)
	rl.DrawText(
		fmt.ctprintf("slowest: %s %.2fms", slow, perf.zone_avg(&g.meter, slow)),
		10,
		34,
		20,
		rl.GRAY,
	)
	if state.is(&g.machine, MENU) {
		ui.title_screen(GAME_TITLE, MENU_LINES[:])
	} else if state.is(&g.machine, PAUSED) {
		ui.overlay(PAUSE_TITLE, PAUSE_HINT)
	}
}
