pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
-- shark girl and lava boy
-- by Christopher Brown, Patrick Romero, Renae Rohde, Maddie White
--[[
    PICO-8 FINAL PROJECT BETA VERSION
    COSC438 - alan jamieson
    Group:
        Christopher Brown
		Patrick Romero
		Renae Rohde
        Maddie White
]]
lives = 0
camerax = 0
music_on = false
sfx_delay = true
boss_aggro = false
--change these to 13*(level number-1)+1 for the level you want to start at. [1,14,27,40]
current_floor = 1
--set this to the level you want to start at. [1,2,3,4]
current_level = 1
boss_intro_time = 5*60
boss_text_index = 0
score = 0
power_ups = {}
player = {
	start_x = 0*8,
	start_y = 8*8,
	x = 0*8,
	y = 8*8,
	w = 5,
	h = 7,
	sx = 1,
	sy = 0,
	can_move = true,
	grounded = false,
	accel = 0,
	maxaceel = 2.5,
	speed = 0.70,
    sprite = 1,
    p_spr = 2,
	flip_sprite_x = false,
	jump_hold = 0,
    anim = 0
}
boss = {
	start_x = 0,
	start_y = 0,
    x = 0,
    y = 0,
    w = 10,
    h = 13,
    sx = 5,
    sy = 2,
    can_move = true,
	grounded = true,
	accel = 0,
	maxaceel = 5,
	speed = 0.12,
    sprite = 77,
	flip_sprite_x = false,
	fire_delay = 0,
	health = 100
}
sprite_x = 0
sprite_y = 0
hard_mode = false
bads = {}
projectiles = {}
lava_geysers = {
	spr_num = 68,
	w = 7,
	h = 7,
	sx = 0,
	sy = 0,
	update_cnt = 0,
	flip = false,
	sprites = {}
}
background_lava = {
    spr_num = 72,
    spr_switch = 104,
    w = 3,
    h = 1,
    update_cnt = 0,
    switch = false,
    sprites = {}
}
flag_x = 0
flag_max_y = 0
level_end = false
update_func = nil
draw_func = nil
input_delay = 0
power_up_time = 3
shield_on = false
speed_on = false
rapidfire_on = false
anim_time = 0
death_timer = 0

function _update60()
    update_func()
end

function _draw()
    draw_func()
end

function update_level_screen()
    if btnp(5) then
		update_func = update_game
        draw_func = draw_game
		current_level += 1
		current_floor += 13
		camerax = 0
		player.x = player.start_x
		player.y = player.start_y
		set_map()
    end
end

function draw_level_screen()
    cls(8)
	camera(0,0)
	--print("you beat level: "..current_level, 24, 2, 7)
	print("now entering level: "..current_level+1, 24, 13, 7)
    print("start the level by",24,24,7)
    print("using the 'x or v' key",24,36,7)
    sspr(sprite_x, sprite_y, 8, 8, 48, 48, 8*4, 8*4, player.flip_sprite_x)
end

function update_pause_screen()
    if btnp(4) then
		update_func = update_game
        draw_func = draw_game
    end
end

function draw_pause_screen()
	print("paused on level "..current_level, camerax + 18, 16, 7)
    print("press either the 'c or z'", camerax + 18,27,7)
    print("key to continue", camerax + 18,39,7)
end

function update_title_screen()
    if btnp(5) then
		update_func = update_char_select
        draw_func = draw_char_select
    end
end

function draw_title_screen()
    cls()
	sspr(82,0,24,24,29,0, 24*3,24*3)
	sspr(0,40,19,19,36,72, 19*3,19*3)
	print("press x to play!", 35, 120, 7)
end

function update_char_select()
    if input_delay == 0 then
        if btn(0) or btn(1) then 
            if hard_mode then
                hard_mode = false
            else
                hard_mode = true
            end
            input_delay = 30
        end
        if hard_mode then
            player.sprite = 19
            sprite_x = 24
            sprite_y = 8
            player.p_spr = 4
        else
            player.sprite = 1
            sprite_x = 8
            sprite_y = 0
            player.p_spr = 2
        end
    else 
        input_delay -= 1
    end
    if btnp(5) then
		update_func = update_game
		input_delay = 0
		cameray = -20
        draw_func = draw_game
		set_map()
    end
end

function draw_char_select()
    cls()
	print("use ⬅️ and ➡️ to choose a", 18, 0, 7)
	print("character", 48, 8, 7)
    print("confirm your selection",22,16,7)
    print("using the 'x or v' key",22,24,7)
    sspr(0,16, 8, 8, 16, 48, 8*4, 8*4) 
    sspr(sprite_x, sprite_y, 8, 8, 48, 48, 8*4, 8*4, player.flip_sprite_x)
    sspr(8,16, 8, 8, 80, 48, 8*4, 8*4)
	print("shoot with the", 30, 88, 7)
	print("'x or v' key", 30, 96, 7)
    print("pause with the", 30,104,7)
    print("the 'z or c' key", 30,112,7) 
end

function rock_bad(x,y,speed,s_num)
    local g = {
		x = x*8,
		y = y*8,
		o_x = x*8,
		o_y = y*8,
		w = 6,
		h = 7,
		sx = 1,
		sy = 0,
		accel = 0,
		speed = -speed,
		s_num = s_num,
		flip = false,
		show = true
	}
    return g
end

function player_animate()
 if btn(⬆️) then -- jump
	if hard_mode then
		player.sprite = 23
	else
		player.sprite = 9
	end
 elseif btn(0) or btn(1) then--run
   if time() - player.anim > .1 then
     player.anim = time()
     player.sprite += 1
     if player.sprite > 21 and hard_mode then
       player.sprite = 19
	 elseif player.sprite > 7 and not hard_mode then
		player.sprite = 5
     end
   end
 else --player idle
	if hard_mode then
		player.sprite = 22
	else
		player.sprite = 8
	end
 end
end

function move_opposition()
    for b in all(bads) do
		local on_screen = b.x >= camerax - 8 and b.x <= camerax + 128
        if b.show and on_screen then
            local move = b.speed
            if check_move(b.x + b.sx + move, b.y + b.sy, b.w, b.h) then
                b.speed = -b.speed
				b.flip = not b.flip
            else
                b.x += move
            end

            local accel = b.accel
        
            if not check_move(b.x + b.sx, b.y + b.sy + accel, b.w, b.h) then
                b.y += accel
            else
                b.accel = 0
            end
            
            b.accel += 0.15
            
            if b.accel > 1.5 then
            b.accel = 1.5
            end
				
			if check_sprite_collision(player.x, player.y, player.sx, player.sy, player.w, player.h, b.x, b.y, b.sx, b.sy, b.w, b.h) and not shield_on then
				music(-1, 200)
				sfx(4)
				reset()
			end
        end
    end
end

function draw_bads()
    for b in all(bads) do
        if b.show then
            spr(b.s_num, b.x, b.y+8,1,1, b.flip)
        end
    end
end

function _init()
	music(0, 4000)
    draw_func = draw_title_screen
    update_func = update_title_screen
    sprite_x = 8
    sprite_y = 0
    palt(0, false)
    palt(11, true)
    lives = 3
end

function set_map()
   	bads = {}
	power_ups = {}
	lava_geysers.sprites = {}
    background_lava.sprites = {}
	   local index = 0
    for i=0,127 do
        for j=0,16 do
            local sprite = mget(i,j+current_floor)
            if fget(sprite,7) then
                add(bads,rock_bad(i,j,.5,sprite))
                mset(i,j+current_floor,0)
            end
			if fget(sprite, 1) then
				boss.x = i*8
				boss.y = j*8
				boss.start_x = i*8
				boss.start_y = j*8
				mset(i,j+current_floor,0)
				mset(i+1,j+current_floor,0)
				mset(i,j+current_floor+1,0)
				mset(i+1,j+current_floor+1,0)
			end
			if sprite == lava_geysers.spr_num then
				add(lava_geysers.sprites, {x = i*8, y = (j)*8})
				mset(i, j+current_floor, 0)
			end
            if sprite == background_lava.spr_num then
                add(background_lava.sprites, {x = i*8, y = j*8})
                mset(i, j+current_floor, 0)
            end
			if sprite == 34 then --sheild
				add(power_ups, {i,j+current_floor,sprite})
			elseif sprite == 37 then -- health
				add(power_ups, {i,j+current_floor,sprite})
			elseif sprite == 35 then -- speed
				add(power_ups, {i,j+current_floor,sprite})
			elseif sprite == 36 then --rapid fire
				add(power_ups, {i,j+current_floor,sprite})
			end
        end
    end
end

function update_death()
	death_timer -= 1 
	if death_timer == 0 then
		if current_level == 4 then
			boss_aggro = false
			boss_intro_time = 5*60
			boss_text_index = 0
			boss.health = 100
			boss.x = boss.start_x
			boss.y = boss.start_y
		end
		music(0, 4000)
		update_func = update_game
		player.x = player.start_x
		player.y = player.start_y
		camerax = 0
		reset_bads()
		reset_powers()
	end
end

function reset()
	if death_timer == 0 then
		death_timer = 30
		lives-=1
		update_func = update_death
		shield_on = false
		speed_on = false
		player.speed = 0.7
		rapidfire_on = false
	end
end

function update_boss_animation()
	update_boss()
	if boss_text_index <= 2 then
		if btnp(5) then
			boss_text_index += 1
		end
	else
		boss_intro_time -= 1
		if boss_intro_time % 30 == 0 then
			boss_jump()
		end
		if boss_intro_time % 5 == 0 then
			boss_move_left(.7)
		end
		if boss_intro_time == 0 then
			music(1, 250)
			boss.fire_delay = 180
			draw_func = draw_game
			update_func = update_game
		end
	end
end

function draw_boss_animation()
	draw_game()
	if boss_text_index == 0 then
		rectfill(camerax, 88, camerax+127,110,0)
		rect(camerax, 88, camerax+127,105,7)
		print("who is this?", camerax+2, 92, 7)
		print("'x' key continue", camerax+2,99,7)
	elseif boss_text_index == 1 then
		rectfill(camerax, 88, camerax+127,110,0)
		rect(camerax, 88, camerax+127,105,7)
		print("have you come to fight me?", camerax+2, 92, 7)
		print("'x' key to continue", camerax+2,99,7)
	elseif boss_text_index == 2 then
		rectfill(camerax, 88, camerax+127,110,0)
		rect(camerax, 88, camerax+127,105,7)
		print("you won't be leaving here alive", camerax+2, 92, 7)
		print("'x' key to continue", camerax+2,99,7)
	else

	end
end

function reset_bads()
    for b in all(bads) do
        b.x = b.o_x
        b.y = b.o_y
        b.show = true
        b.speed = -.5
		b.flip = false
    end
	projectiles = {}
end

function reset_powers()
    for p in all(power_ups) do
		mset(p[1],p[2],p[3])
    end
end

function gravity()
    local dy = player.accel
    
	local x = player.x + player.sx
	local y = player.y + player.sy + dy 
    if not check_move(x, y, player.w, player.h) then
		-- not inside a block
        player.y += dy
        player.grounded = false
		sfx_delay = false
    else
		-- check if they are not inside the roof, thus they are inside the ground
		if not (check_flag(x, y) or check_flag(x + player.w, y)) then
			if player.grounded == false and sfx_delay == false then
				sfx(6)
				sfx_delay = true
			end
			player.grounded = true
		end
		player.accel = 0
		player.jump_hold = 0
    end
    
    player.accel += 0.15
    
    if player.accel > player.maxaceel then
      player.accel = player.maxaceel
    end
end

function update_game()
    local dx = 0
    gravity()
	
    if btn(0) then
        dx = -player.speed
		player.flip_sprite_x = true
    end
    if btn(1) then
        dx = player.speed
		player.flip_sprite_x = false
    end
	
	if btn(2) then
		if player.grounded then
			sfx(5)
			player.accel = -1.3
			player.grounded = false
			player.jump_hold = 1
		end
		if player.jump_hold > 0 and player.jump_hold <= 40 then
			player.accel += (-0.55 / (player.jump_hold))
			player.jump_hold += 1
		end
	elseif player.jump_hold > 0 then
		player.jump_hold = 0
	end
	
	local new_pos = {
		x = player.x + player.sx + dx,
		y = player.y + player.sy
	}

    player_animate()
	
    player.can_move = not check_move(new_pos.x, new_pos.y, player.w, player.h)
    if check_end(new_pos.x, new_pos.y, player.w, player.h) then
        draw_func = draw_level_screen
		update_func = update_level_screen
    end
    if player.can_move and player.x + dx > camerax then
        player.x += dx
	end
    
	local p_box = {
		x1 = player.x + player.sx,
		y1 = player.y + player.sy,
		x2 = player.x + player.sx + player.w,
		y2 = player.y + player.sy + player.h
	}
	
	local powerup_cell = get_flag_box(p_box, 6)
    if powerup_cell != null then
		anim_time = time() + power_up_time
		local map_x = powerup_cell.x
		local map_y = powerup_cell.y
		printh(map_x)
		printh(map_y)
		if check_flag_map(map_x, map_y, 2) and check_flag_map(map_x, map_y, 4) then --sheild
            powerup_shield(anim_time)
			sfx(18)
		elseif check_flag_map(map_x, map_y, 2) and not check_flag_map(map_x, map_y, 4) then -- health
            powerup_health()
			sfx(17)
		elseif check_flag_map(map_x, map_y, 4) and not check_flag_map(map_x, map_y, 2) then -- speed
            powerup_speed(anim_time)
			sfx(19)
		elseif check_flag_map(map_x, map_y, 5) then --rapid fire
            powerup_rapidfire(anim_time)
			sfx(20)
        end
		
		mset(map_x, map_y + current_floor - 1, 0)
    end
    
    if shield_on then
        powerup_shield(anim_time)
    end
    if speed_on then
        powerup_speed(anim_time)
    end
    if rapidfire_on then
        powerup_rapidfire(anim_time)
    end    

	if btnp(4) then
        draw_func = draw_pause_screen
		update_func = update_pause_screen
	end

	if input_delay == 0 then
		if btnp(5) then
			-- projectiles
			shoot_projectile(player.x, player.y, player.flip_sprite_x)
			input_delay = 30
		end
	else 
		input_delay -= 1
	end

	if current_level == 4 and player.x >= 96*8 and not boss_aggro then
		player.start_x = 90*8
		music(-1,700)
	end
	if current_level == 4 and player.x >= 114*8 and not boss_aggro then
		boss_aggro = true
		draw_func = draw_boss_animation
		update_func = update_boss_animation
	end
    check_death()
    move_opposition()
	move_projectiles()
	update_lava_geysers()
    animate_lava()
	if current_level == 4 and boss_intro_time == 0 and boss.health > 0 then
		update_boss()
		boss_ai()
	end
end

function get_flag_box(box, flag)
	if check_flag(box.x1, box.y1, flag) then
		return {x = flr(box.x1 / 8), y = flr(box.y1 / 8) + 1}
	elseif check_flag(box.x2, box.y2, flag) then
		return {x = flr(box.x2 / 8), y = flr(box.y2 / 8) + 1}
	end
	return null
end

--power-ups
function powerup_shield(anim_time)
    if(time() < anim_time) then
        shield_on = true
    else
        shield_on = false
		sfx(21)
    end

end

function powerup_health()
    if lives < 3 then
        lives += 1
	else
		score += 500
    end
end

function powerup_speed(anim_time)
    if(time() < anim_time) then
        player.speed = 1.4
        speed_on = true
    else
        player.speed = .7
        speed_on = false
		sfx(21)
    end
end

function powerup_rapidfire(anim_time)
    if(time() < anim_time) then
        if btnp(5) then
            shoot_projectile(player.x, player.y, player.flip_sprite_x)
        end
        rapidfire_on = true
    else
        rapidfire_on = false
		sfx(21)
    end
end

function shoot_projectile(x, y, flp)
    sfx(40, 1)
	local p = {
		spr = player.p_spr,
		x = x,
		y = y,
		sx = 0,
		sy = 1,
		w = 7,
		h = 5,
		flp = flp,
		bad = false
	}
	add(projectiles, p)
end

function move_projectiles()
	for p in all(projectiles) do
		local dx = (p.flp and -2 or 2)
		-- check collision with map or outside of map
		if p.x + p.w < camerax or 
		   p.x - p.w > camerax + 255 or
		   check_move(p.x + p.sx + dx, p.y + p.sy, p.w, p.h) then
			del(projectiles, p)
			sfx(10)
		else
			-- check sprite collision
			for b in all(bads) do
				if b.show then
					local collide = check_sprite_collision(p.x, p.y, p.sx, p.sy, p.w, p.h, b.x, b.y, b.sx, b.sy, b.w, b.h)
					if collide then
						del(projectiles, p)
						-- kill baddie
						b.show = false
						score += 100
						sfx(9)
						return
					end
				end
			end
			if p.bad and check_sprite_collision(p.x, p.y, p.sx, p.sy, p.w, p.h, player.x, player.y, player.sx, player.sy, player.w, player.h) then
				music(-1, 200)
				sfx(4)
				reset()
			end
			if boss_aggro and not p.bad and boss.health > 0 and check_sprite_collision(p.x, p.y, p.sx, p.sy, p.w, p.h, boss.x, boss.y, boss.sx, boss.sy, boss.w, boss.h) then
				boss.health -= 2.5
				del(projectiles, p)
				sfx(10)
			end
			p.x += dx
		end
	end
end

function update_lava_geysers()
	lava_geysers.update_cnt += 1
	if lava_geysers.update_cnt % 15 == 0 then
		lava_geysers.update_cnt = 0
		lava_geysers.flip = not lava_geysers.flip
	end
end

--[[
	check if the two sprites are inside one another.
	x1 - x position of sprite 1
	y1 - y position of sprite 1
	sx1 - starting x of sprite 1
	sy1 - starting y of sprite 1
	w1 - width of sprite 1, '0' denotes that the width is 1 pixel
	h1 - height of sprite 1, '0' denotes that the height is 1 pixel
--]]
function check_sprite_collision(x1, y1, sx1, sy1, w1, h1, x2, y2, sx2, sy2, w2, h2)
	local spr1_x = x1 + sx1
	local spr1_y = y1 + sy1
	local spr2_x = x2 + sx2
	local spr2_y = y2 + sy2
	return abs(spr1_x - spr2_x) * 2 <= w1 + w2 + 1 and
	       abs(spr1_y - spr2_y) * 2 <= h1 + h2 + 1
end

function draw_projectiles()
	for p in all(projectiles) do
		spr(p.spr, p.x, p.y+8, 1, 1, p.flp)
	end
end

function check_end(x,y,w,h)
    return check_move(x,y,w,h,3)
end 

function check_death()
	local dead = false

	-- fell out of map
    if player.y > (128) then
		sfx(8)
        dead = true
    end
	
	-- touched a lava geyser
	if not dead and hard_mode and not shield_on then
		local lgs = lava_geysers.sprites
		local i = 1
		while i <= #lgs and not dead do
			local lg = lgs[i]
			if check_sprite_collision(lg.x, lg.y, lava_geysers.sx, lava_geysers.sy, lava_geysers.w, lava_geysers.h, player.x, player.y, player.sx, player.sy, player.w, player.h) then
				dead = true
				sfx(7)
			end
			i += 1
		end
	end
	
	if dead then
		if score - 500 <= 0 then
			score = 0
		else
			score -= 500
		end
        reset()
	end
end


function boss_gravity()

    local dy = boss.accel
    
	local new_pos = {
		x = boss.x + boss.sx,
		y = boss.y + boss.sy + dy
	}
    if not check_move(new_pos.x, new_pos.y, boss.w, boss.h) then
		-- not inside a block
        boss.y += dy
        boss.grounded = false
    else
		-- check if they are not inside the roof, thus they are inside the ground
		if not (check_flag(new_pos.x, new_pos.y) or check_flag(new_pos.x + boss.w, new_pos.y)) then
			if boss.grounded == false then
				sfx(6)
			end
			boss.grounded = true
		end
		boss.accel = 0
    end
    
    boss.accel += 0.15
    
    if boss.accel > boss.maxaceel then
      boss.accel = boss.maxaceel
    end
end

function boss_move_right(speed)
	speed = speed or boss.speed
	boss.flip_sprite_x = true
	update_boss(speed)
end

function boss_move_left(speed)
	speed = speed or boss.speed
	boss.flip_sprite_x = false
	update_boss(-speed)
end

function boss_jump()
	if boss.grounded then
		sfx(5)
		boss.accel = -2.6
		boss.grounded = false
		update_boss()
	end
end

function boss_fire()
	if boss.fire_delay == 0 then
		boss.sprite = 75
		sfx(40, 1)
		local p = {
			spr = 17,
			x = boss.x,
			y = boss.y,
			sx = 0,
			sy = 1,
			w = 7,
			h = 5,
			flp = not boss.flip_sprite_x,
			bad = true
		}
		add(projectiles, p)
		boss.fire_delay = 180
	end
end

function boss_ai()
		local rn = flr(rnd(4))+1
		if rn == 1 then
			--boss_move_left()
		elseif rn == 2 then
			--boss_move_right()
		elseif rn == 3 then
			--boss_jump()
		else
			boss_fire()
		end
		if flr(player.x) > flr(boss.x) then
			boss_move_right()
		elseif flr(player.x) < flr(boss.x) then
			boss_move_left()
		end
end

function update_boss(dx)
	dx = dx or 0
    boss_gravity(dx)

	local new_pos = {
		x = boss.x + boss.sx + dx,
		y = boss.y + boss.sy - 1
	}
    boss.can_move = not check_move(new_pos.x, new_pos.y, boss.w, boss.h)
    if boss.can_move then
        boss.x += dx
	end
	if boss.fire_delay < 60 then
		boss.sprite = 77
	end
	if boss.fire_delay > 0 then
		boss.fire_delay -= 1
	end

	if check_sprite_collision(player.x, player.y, player.sx, player.sy, player.w, player.h, boss.x, boss.y, boss.sx+2, boss.sy+3, boss.w-2, boss.h) then
		music(-1, 200)
		sfx(4)
		reset()
	end

end


function draw_boss()
	if boss.health > 0 then
		spr(boss.sprite,boss.x,boss.y+8,2,2, boss.flip_sprite_x)
	end
end

function check_move(x,y,w,h,f)
    f = f or 0
    return check_flag(x+w, y, f) or
            check_flag(x, y+h, f) or
            check_flag(x, y, f) or
            check_flag(x+w, y+h, f)
end
function check_flag_map(x, y, f)
    return fget(mget(x, y + current_floor - 1),f)
end
function check_flag(x, y, f)
    return fget(mget(x/8,(y/8)+current_floor),f)
end
function update_game_over()
--temp blank for the moment 
	music(-1, 500)
end

function animate_lava()
    background_lava.update_cnt += 1
	if background_lava.update_cnt % 12 == 0 then
		background_lava.update_cnt = 0
		background_lava.switch = not background_lava.switch
	end
end

function draw_game()
    if lives > 0 and boss.health > 0 then
        if player.x - 60 > camerax then
            camerax = player.x - 60
		end
		if camerax + 128 > 128*8 then
			camerax = 128*7
		end
        -- cameray = player.y - 60 
        camera(camerax, cameray)
		   if current_level == 1 then cls(12)
		   elseif current_level == 2 then cls(5)
		   else cls(8) end
        map(0,current_floor,0,8,128,16)
        for bl in all(background_lava.sprites) do
            if background_lava.switch then
                spr(background_lava.spr_switch, bl.x, bl.y+8, background_lava.w, background_lava.h)
            else
                spr(background_lava.spr_num, bl.x, bl.y+8, background_lava.w, background_lava.h)
end  
		end
		draw_bads()
	    draw_projectiles()
		if (shield_on) then
			if (hard_mode) then
				pal(6,5)
			else
				pal(15,5)
			end
		end
		spr(player.sprite, player.x, player.y+8, 1, 1, player.flip_sprite_x)
		pal()
		palt(0,false)
		palt(11,true)
		for lg in all(lava_geysers.sprites) do
			spr(lava_geysers.spr_num, lg.x, lg.y+8, 1, 1, lava_geysers.flip) 
		end
        print("lives: ",camerax,cameray,7)
        for i=1,lives do
            spr(3, camerax + 18 + (8*i), cameray-1)
        end
		print("score: "..score,camerax,cameray + 8,7)
		if boss_aggro then 
			print("boss health: "..boss.health,camerax,cameray + 16,7)
		end
		-- print("firedelay: "..boss.fire_delay,camerax,cameray + 16,7)
		if current_level == 4 then
			draw_boss()
		end
	elseif boss.health < 1 then
		update_func = update_game_over
        player.x = 0
        player.y = 0
        camera(0,0)
        cls(0)
		print("you won!!! :)",35,30,7)
		print("your final score was: "..score,15,100,7)
		sspr(sprite_x, sprite_y, 8, 8, 48, 48, 8*4, 8*4, player.flip_sprite_x)
    else
		update_func = update_game_over
        player.x = 0
        player.y = 0
        camera(0,0)
        cls()
		print("game ♥ over!!!",35,60,7)
		print("your final score was: "..score,15,80,7)
        print("press ctr + r",40,68,7)
    end
end
__gfx__
00000000bb2222bbbbbbbbbbbbbbbbbbbbbbbbbbbb2222bbbb2222bbbb2222bbbb2222bbbb2222bb000cc00c00c00cc00ccc00c00c0000000000000000000000
00000000b22f4fbbbbbb99bbbaaaaaabbbbb11bbb22f4fbbb22f4fbbb22f4fbbb2ffff2bb22f4fbb00c11c0c00c0c11c0c11c0c00c0000000000000000000000
00700700b22ffffbb999944bba0aa0abb1111ddbb22ffffbb22ffffbb22ffffbb2f4f42bb22ffffb00c0010c00c0c00c0c10c0c0c10000000000000000000000
00077000bb2fffbb9aaa444fbaaaaaab1cccddd6bb2fffbbbb2fffbbbb2fffbbbbffffbbbb2fffbb001cc00cccc0cccc0ccc10cc100000000000000000000000
00077000bbe89ebbb9aa4f44ba0aa0abb1ccd6ddbbe09ebbb0009ebbbbe0000fb0e9ee0bb0009e0f00011c0c11c0c11c0c11c0c1c00000000000000000000000
00700700bb98f9fbb999944bba0000abb1111ddbbb90f9fbbf9aa9fbbb9aa9bbb09aa90bbf9aa9bb00c00c0c00c0c00c0c00c0c01c0000000000000000000000
00000000bbe9aebbbbbb99bbbaaaaaabbbbb11bbbbe9aebbbbe9aebbbbe9aebbbfe9aefbbbe9aebb001cc10c00c0c00c0c00c0c00c0000000000000000000000
00000000bb22b22bbbbbbbbbbbbbbbbbbbbbbbbbbb00b00bbb0bb00bbb00b0bbb00bb00bbb0bb0bb000110010010100101001010010000000000000000000000
bbbbb5bbbbbbbbbb00000000bb1111bbbb1111bbbb1111bbbb1111bbbb1111bb0000000000000000000000000000000000000000000000000000000000000000
bbbb565bbbbb00bb00000000b116c6bbb116c6bbb116c6bbb166661bb116c6bb0000000000000000000000cc00ccc0ccc00c0000000000000000000000000000
bb556665b000055b00000000b116666bb116666bb116666bb16c6c1bb116666b000000000000000000000c11c01c10c11c0c0000000000000000000000000000
b56665650666555d00000000b11666bbb11666bbb11666bbb166661bb11666bb000000000000000000000c00100c00c00c0c0000000000000000000000000000
b5060665b0665d5500000000b1dcddbbbcccddbbb1dcccc6bcddddcbbcccddc6000000000000000000000c0cc00c00ccc10c0000000000000000000000000000
b5666655b000055b00000000bbdc676bb6ddd76bbbddd7bbbcd77dcbb6ddd7bb000000000000000000000c01c00c00c11c0c0000000000000000000000000000
b556555bbbbb00bb00000000bbddd7bbbbddd7bbbbddd7bbb6d77d6bbbddd7bb0000000000000000000001cc10ccc0c00c0cccc0000000000000000000000000
bb5555bbbbbbbbbb00000000bb11b11bbb1bb11bbb11b1bbb11bb11bbb1bb1bb0000000000000000000000110011101001011110000000000000000000000000
bbbbb888cccbbbbbbb1111bbbbbbbbbbbbb222bbbbbbbbbb00000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbb8888ccccbbbb111cc111fbbbfbbbbbb2d2bbbaaaaaab0000000000000000000000000000000000000000dd000dd00ddd0000000000000000000000000000
bbb88888cccccbbb11cccc11ffbbffbbbbb222bbba0aa0ab000000000000000000000000000000000000000d00d0d00d0d00d000000000000000000000000000
bb888888ccccccbb11cccc11fffbfffbbbbbbbbbbaaaaaab000000000000000000000000000000000000000d00d0d00d0d00d000000000000000000000000000
bb288888ccccc1bb111cc111ffebffebbbbbbbbbba0aa0ab000000000000000000000000000000000000000dddd0d00d0d00d000000000000000000000000000
bbb28888cccc1bbbb111111bfebbfebb999bb111ba0000ab000000000000000000000000000000000000000d00d0d00d0d00d000000000000000000000000000
bbbb2888ccc1bbbbbb1111bbebbbebbb9a9bb1c1baaaaaab000000000000000000000000000000000000000d00d0d00d0d00d000000000000000000000000000
bbbbb288cc1bbbbbbbb11bbbbbbbbbbb999bb111bbbbbbbb000000000000000000000000000000000000000d00d0d00d0ddd0000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88888888566666655555565555555689babbabbb655555566555555665555556088888888888888888888800bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000
88888888656666566555555569555589bb9a9aba565555655655556556555565000888888888888888888009bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000
88888888665665665555555559555555a999999a556556555565565555655655990008888888888888800099bbbbb9999bbbbbbbbbbbb99995bbbbbb00000000
88888888666556665656555656568956bba999ab555665555550055555566555a9a9000888000888800099a8bbbb449059bbbbbbbbbbba9059bbbbbb00000000
88888888666556665555555555558955a999999a555665555550055555566555a989990088099080009a9aa8bbbbbba555bbbbbbbbbbb00555bbbbbb00000000
88888888665665665555555655589556ba9999aa556556555565565555655655888aa99a0009a00999a8aa88bbbb554589bbbbbbbbbbb54589bbbbbb00000000
88888888656666565655655586556555bba999ab56555565565555655655556588888a980999899aaa888a88bbbbbbb595bbbbbbbbbbbbb595bbbbbb00000000
88888888566666655555555589555555bba99abb6555555665555556000000008888a9889aa88aa888888888bbbbb955955abbbbbbbbb955955bbbbb00000000
000000000000000000000000ccccccccffafffffffafaffaccccccccbbb161bb088888888888888888888800bb459a55584a95bbbb459a55584a95bb00000000
200000220020020022000000ccccccccf4f4ff4ff4fff4ffcc6777ccbb16661b000888888888888888888009bb589995555a859bbb589995555a859b00000000
800002882080080288200000ccccccccfffffaffaff4ffafc6677777b166161b990008888888888888800099b55abb58a955549bb55abb58a9b5549b00000000
800008008080080800800000ccccccccfaffffffffffaf4a6677777716611661a9aa00088800088880009999b5555b555abb94bbb5555b555abbb54b00000000
800008228080080822800000ccccccccff4ff4faf4aff4ff7777776666111166a98a990088099080009a99a9bb45bb5a9555bbbbbb45b55a9555bbbb00000000
800008888082280888800000ccccccccaffaffffffffafaf7777666c11116111a98a999a0009a009999a9aaabbbbba4bb599bbbbbbbbba4bb599bbbb00000000
822208008088880800800000ccccccccf4fff4fff4ff4f4fcc776ccc11666661a8888a9a0999a999aa98aaa8bbbb58bbb5895bbbbbbb58bbb5895bbb00000000
888808008008800800800000ccccccccfffffffaaff4fafacccccccc66611166888888a999aa89aa8a888a88bbb444bbbb455bbbbbb444bbbb455bbb00000000
000000000000000000000000000000004ffffff4f444444f00000000111111110888888888888888888888000000000000000000000000000000000000000000
00022200022002002000000000000000f4ffff4f4f4444f400000000116616610008888888888888888880090000000000000000000000000000000000000000
00088820288208008000000000000000ff4ff4ff44f44f440000000066616616a9000888888888888880009a0000000000000000000000000000000000000000
00080080800808008000000000000000fff44fff444ff4440000000011111111a9aa00088800088880009a980000000000000000000000000000000000000000
00082280800808228000000000000000fff44fff444ff444000000001111111199aa99008809a080009aa8aa0000000000000000000000000000000000000000
00088820800800880000000000000000ff4ff4ff44f44f4400000000166166168a8aa99900089009999a888a0000000000000000000000000000000000000000
00080080800800880000000000000000f4ffff4f4f4444f400000000661611668888aaa909a88a9aa8a988880000000000000000000000000000000000000000
000822808228008800000000000000004ffffff4f444444f0000000011111111888aa88aa88888a888a888880000000000000000000000000000000000000000
00088800088000880000000000000000666665666666658955555555055555500000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000566666665966668955555555555550550000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000666666666966666655555555550555550000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000656566656565896555555555055555550000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000666666666666896655555555550555050000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000666666656668966555555555555555550000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000656656668566566655555555055505500000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000666666668966666655555555550555550000000000000000000000000000000000000000000000000000000000000000
04040404040404040404040404040404840404040404040404040404040404040404040404040404040404040404048404040414040404040404040404040404
04140404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404045454
04040414040414040414040404040404040404040404040414040404040404040404140404140404040404040404040404140404040404040404040404040404
04040452040404040404040404040404040404140404040404040404040404041404040414040404840404042204040404040404040404041404040404045454
04040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404
04040404040404040404040404040404040414140404040404040404040404040404040404040404040404040404040404040404040404141404040404045464
04040404040444440404040104040404044404040404040404040404040404440404010404040444040404040401040404040401040404440404040404040404
04040404040401040404440404040104041414140404040404440404010404040404040404040404040404040404010404040444040414141404040404047474
24242424242434242424242424242424242424242424240404040424242424242424242424243424242424242424242424242424242424242424242424242404
04340404242424242424242424242424342424242424242424242424242424242424242424242424040424242424242424242424242424242424242424242424
24243424242424342424243424242424242424243424240404040424243434242424242424242424242434242434242424342424242424342424342424342404
04240404242424243424243424242424242424242424342424242424242424243424242434243424040424342434243424242424342424242424242434242434
24242424242424242424242424342424242434242434244444444424242424243424343424242424342424242424242424243424342424242424242424242444
44344444242424342424242424242424242434242424242424342424243424242424342424242424444424242424243434342424343424242424342424242424
24242424342424242424242424242424242424242424244444444424242424242424242424242424242424242424342424242424342424242434242424242444
44244444242424242424242424242424242424242424242424242424242424242424242424242434444424342424242424242424242434242424242424242434
04040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404
04040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404
04040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404
04840404040404040404040404040404040404040484040404040404040404040404040404040404040404040404040404040404040404040404040404040404
04048404040404040404040404040404040404040484040404040404040404040404040404040484040404040404040404040484040404040404040404040404
04040404040404040404040404040404040404040404040404040404040404040404040404040404040404048404040404040404040404040404840404040404
04040404040404040404040404040404840404040404040404040404040404040404040404040404040404040404040404040404040404040484040404040404
04040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040444
04040404040404048404040404040404040404040404040404040404040404840404040404040404045204040404040404040404040404040404040404040432
04040404040404040404040404040484040404040404040404040404040484040404040404040404140404040404040404040404040404040404040404044434
04040404040404040404040404040404040404420404040404040404040404040404040404040414040404040404040404040404040404040404040404040404
04040404040404041404140404040404040404040404040404040404040404040404040404040414140404040404040404040484040404040404040404044434
04040404040404040404040404040404040404040414040404041404040404040404040404140404040404040404840404040404040414040404041414141404
04040404040414040404040404040404040404040404040414040404040404040404520404041414140404040404040404040404040404040404040442044434
04040414041404040404040404040404040404041414040404040404040404040404041404040404041404040404040404040404041414040404040404040404
040404040404040404040404040404040404040404040404040404040404040404040404041414141404040404044204040404040404040404b4c40404044434
04040404010404044404040404040404040404141414044404040401040444040404040404040404040404040404040404010404141414044404010404010404
040444040401040401040404440404010404010404040404040404040404440401040404141414141404040404040404040404040404040404b5c50404044434
24242424242424242424242424040404342424242424242424242424243424243424040404040404040404140424242424242424242424242424242424242424
24242424242424242424242424242424242434242424240404242424242424242424242424242424242424242424242424242434242424242424242434242424
24342424243424243424242424040404242424242434242424342424242424242424040404040404040404040424243424242434242424242434242424242434
24242424342424242424242434242424242424243424240404242424342424343424342424242424242424242434242424242424242424243424243424242434
24242434242424243424243424444444342424243424242434242434242434242424444444444444444444444424242424242424343434242424243424242424
24242424242424342424342424242424342424242424244444242424242424242424242424342424242424242424243424242434243424242424242434243424
24242424342424242424242424444444242424242424242424242424242424243424444444444444444444444424242434242424242424242424242424242424
34242424242424242424242424242424242424242424244444242424342424242424242424242424342434242424242424242424242424242424243424242424
__gff__
0000000000000000000000000000000080000000000000000000000000000000000054506044000000000000000000000000000000000000000000000000000000010101000909090000000200000000000000000101000000000000000000000000000001010000000000000000000000000000010100000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
5353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353
5353535353535353535356565353535353535353535353535356535353565656535353535353535353535353535353535353535653535353535656535353535353535353535353535353535353535353535353535353535656535353535353535353535353535353535353535353535325535353535653535353535353535353
5353535656535353535353535353535353535353535353535353535353535353535353535353535353535656535353535353535353535353535353535353535353535356565353535353535353535353535353535353535353535353565353535353535353565353535353535353535353535353535353535353535353535656
5353535356565353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535356565353535353535353656565536565655353535353535656535353535353
5353535353535353535353565353535353535353535356565353535353535353535656535353535353535353535353535356565353535353535353535353535353535353535353535353535353535353565653535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353
5353535353535353535353535353565653535353535353535353535356535353535353535353565353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353656565535353535356565353535353535353535353535353
5353535353535353535322535353535353535353535353535353535353535353535353531053535353535353535353105310531053535353535353565653535353565353535353535353531053535353535653535353535353535353535353531053535353105353535353535353535353535353535353535353535353534545
5353535353536553655365535353535365535353565353535353535353536553535353226553535353535353535353655365536553535353535353535353535353535353535310535353536565652453535353535353535353535353655365536553535353656565535353535353535353535353535353655353565353534545
5353565353535353535353535353535353535353535353535353535353656553535353535353535353535353535353535353535353535353535353535353535353535365535365535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535365655353535353534546
5353535353535353535353535353535353535310535353535353535365656553535353535353535353535353535353535353235353535353535310535353535353536565535365655353535353535353535353535353535353535353535353535353535310535353535353535353535353535353536565655353535353104747
5454545454545554545554545454545454545454545454535354545454555454545454545454545454535354545454545454555454545454545454535354545454545454555454545454545455545554545455545353545455545454545454555454545454555454545454555454545454545353545454545554545454555454
5455545454545454545454545554545554545554545554575754555454545454545454555454555454575754555454555454545454545554555455575755545454555454545455545454555454545454555454545757545454545454555454545454545554545454545554545454545555545757555455545455545455545454
5454545454555454545454545454545454555454545454676754545554545455545454545454545554676754545454545455545455545454545454676754545554545454555454545554545454545554545455546767545554545554545454555455545455545455545454545554545455546767545554545454555454545554
5455545455545454545454545554545454545455545454676754545454545454545455545455545454676754545554545454545454545455545454676754545454545454545454545454545455545454545454546767545454545454545454545454545454545454545454555454545454546767545454555454545454545455
7676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676
7676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676
7676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676
7676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676
7676767676767676767676764176767676767676767676767676767676767676767676767676767641767676767676767676767676767676767676767676767676767676767676767676767676767676764176767676767676767676767676767676767676767676767676767676762576767676767676767676767676767676
7676767676767676237676767676767676767622767676767676767676767676767676767676417676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676764545
7676417676767676417676767676767676767676767676767676767676417676767676764176767676767676762476767676767676767676767676417676767676417676417676417622767676767641767676767676767676767676767676764176764176767676767676767676764176767676767676764176767676764545
7676767676767676767676767676767676767641767676767676767676767676767676767676767676767676767676767676767676767676417676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767641767676767676767676767676767676414176767676764546
7676767641767610767623767676767676767641767676761076767676767676767676761076767676767676767676767676767676767676414176767676107676767676761076767676767676767610767676767676767610767676767676761076767676764141767610767676767676767676767641414176767676764747
7474757475747474747474757676747474747474747474757474747676747475747474747574747474747574757474747474767674747475747474747474747474757474747474747474747574747474757474747474747474747476767475747475747474757474747474747474747475747676747475747474747474757474
7475747474757475747574747676747574747574747574747474757676747474747475747474747475747474747474757474767674757474747574747474757474747474757474747475747574747574747475747475747474747576767474747474747474747475747475747474757474747676757474747574747574747474
7474757475747474757474744444747474747474757474747574744444747574747474747474757474747475747574747474444474747474747474747574747574747474747474757474747474757474757474747474747574757444447474757475747574757474747474747474747475744444747475747474757474757474
7574747474747574747474754444747475747474747474757474744444747574747574747574747474757474747474747475444474747475747574747474747474757475747474747474747574747474747474747574747474747444447474747474747475747474747574747574747474744444757474747474747474747475
4040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
4040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404840404040404040
4040404040404040484040404040404040404040404040404040404048404040404040404040404840404040404040404040404040234040404040404048404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
4840404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404048404040404040404040404040404040404040404040404040404040404040484040404040404040404040404040404040
4040404040404040402340404040404040404040404040402440404040404040404040404040404040404040404040404040404040414040414040404040404040404040404040404048404040404040404040404040404040404840404040404040404040404040404040404040404040404040404040404040404040404040
__sfx__
001000002850022500295502a55029550285501950026550155002555024550275002355021550205501d5501c5500e5000e50000500005000050000500005000050000500005000050000500005000050000500
00100000220100e0100c0100c0500c0500d050180501a0501c0501d0501f05021050230502a050320502c0501205014050160500c0500e0501005011050130501505017050190501b050190501b0501e05020050
001c00000c5300c53004530155301f53016530115300f5300f530145301d530205301c530165300e530075300f530165301d53023530275302953027530215301b53012530105300c5300c5300a5300c5300a530
00200000106100f6100e6100d6100c61012610186101e6102261024610226101f6101c61019610156100f6100c61009610076100a6100e610116101461016610186101a6101761015610136100e6100a61009610
011000000f7400d740007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700000000000000000000000000000000000000000000000000000000000000
000100000703006030050300403004030030300203003050080601307013000290000b00000000000000f000000000000014000000001900000000000001f0002400000000280002d00036000000000000000000
00010000100300a030050300103000030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00030000006000d6400d6400d6400e6400e640106400f640116401364015640186401b6401f640216400060000600006000060000600006000060000600006000060000600006000060000600006000060000600
000200003b5403a5403854033540345403154031540005402b540245402854025540265401f5402354018540205401754000540125401a5400d540155400a5400854005540045400254000540055400454002540
000200003b600396002c6400060031600006002c60000600276001864022600006001d6000060018600006000a60010600006000e6000d6000c6000a600086000f60005600046000460004600036000060000600
000200000c64000600046000060000600006003d60000600006000060000600006000060000600026000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
001400200d7300f7300d7300f7300d7300f7300d7300f7300d7300f7300d7300f7300d7300f7300d7300f7300d7300f7300d7300f7300d7300f7300d7300f7300d7300f7300d7300f7300d7300f7300d7300f730
0010000018520005001a520005001c5201c520005001852018520005001c5200050018520005001c5200050018520005001c5200050018520005001c5200050018520005001a520005001c5201c5200050018520
001000001f5200050024520005002352023520005001f5201f5200050023520005001f5200050023520005001f5200050023520005001f5200050023520005001f5200050024520005002352023520005001f520
001000001f5400050023540005001f5400050023540005001f5400050024540005002354023540005001f54000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000d540000000f540000001254012540000000d5400d540000000f5400d5000d54000000125400d5000d540000000f5400d5000d5400000012540000000d540000000f540000001254012540000000d540
00140000007000070000700007000070000700007000070000700007000070000700007000070000700007000d7300f7300d7300f7300d7300f7300d7300f7300d7300f7300d7300f7300d7300f7300d7300f730
00060000205402354025540295402d500335002350035500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500
000400001f2401b24016240192401d240202400020000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200
000300001344012440124401344016440194401a4001c4001c4001a40018400144001740018400194000040000400004000040000400004000040000400004000040000400004000040000400004000040000400
000600000174004740097400d74010740147401674000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
0004000000300233501c350193501835017300183001530000300103000f3000d3000c3000a3000a3000a30000300003000030000300003000030000300003000030000300003000030000300003000030000300
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000365000600006000060000600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
02 0242434b
01 0c0d4c0b
02 0c0d4310

