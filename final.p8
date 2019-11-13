pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
lives = 0
camerax = -128
music_on = false
--note door flag is 3
player = {
	x = 8,
	y = 0,
	w = 3,
	h = 7,
	sx = 2,
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
current_floor = 120
boss = {
    x = 0,
    y = 0,
    w = 0,
    h = 0,
    sx = 0,
    sy = 0,
    can_move = true,
	grounded = false,
	accel = 0,
	maxaceel = 2.5,
	speed = 0.70,
    sprite = 1,
	flip_sprite_x = false,
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
flag_x = 0
flag_max_y = 0
level_end = false
update_fuc = nil
draw_func = nil
input_delay = 0

death_timer = 0

function _update60()
    update_func()
end

function _draw()
    draw_func()
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
        draw_func = draw_game
    end
end

function draw_char_select()
    cls() 
	print("use ⬅️ and ➡️ to choose a", 18, 0, 7)
	print("character", 48, 8, 7)
    print("confirm your selection",22,16,7)
    print("using the 'x' key",30,24,7)
    sspr(0,16, 8, 8, 16, 48, 8*4, 8*4) 
    sspr(sprite_x, sprite_y, 8, 8, 48, 48, 8*4, 8*4, player.flip_sprite_x)
    sspr(8,16, 8, 8, 80, 48, 8*4, 8*4) 
end

function flame_bad(x,y,speed,s_num)
    local g = {
		x = x*8,
		y = y*8,
		o_x = x*8,
		o_y = y*8,
		w = 5,
		h = 5,
		sx = 1,
		sy = 2,
		accel = 0,
		speed = -speed,
		s_num = s_num,
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
    for g in all(bads) do
		local on_screen = g.x >= camerax - 8 and g.x <= camerax + 128
        if g.show and on_screen then
            local move = g.speed
            if check_move(g.x + g.sx + move, g.y + g.sy, g.w, g.h) then
                g.speed = -g.speed
            else
                g.x += move
            end

            local accel = g.accel
        
            if not check_move(g.x + g.sx, g.y + g.sy + accel, g.w, g.h) then
                g.y += accel
            else
                g.accel = 0
            end
            
            g.accel += 0.15
            
            if g.accel > 1.5 then
            g.accel = 1.5
            end
				
			if check_sprite_collision(player.x, player.y, player.sx, player.sy, player.w, player.h, g.x, g.y, g.sx, g.sy, g.w, g.h) then
				music(-1, 200)
				sfx(4, 0)
				reset()
			end
        end
    end
end

function draw_bads()
    for g in all(bads) do
        if g.show then
            spr(g.s_num, g.x, g.y)
        end
    end
end

function _init()
    draw_func = draw_char_select
    update_func = update_char_select
    sprite_x = 8
    sprite_y = 0
    music(0)
    palt(0, false)
    palt(11, true)
    lives = 3
    local index = 0
    for i=0,127 do
        for j=0,16 do
            local sprite = mget(i,j)
            if fget(sprite,7) then
                add(bads,flame_bad(i,j,.5,sprite))
                mset(i,j,64)
            end
            if fget(sprite, 4) then
                flag_x = i*8 + 5
                flag_max_y = j*8 + 5
            end
			if sprite == lava_geysers.spr_num then
				add(lava_geysers.sprites, {x = i*8, y = j*8})
				mset(i, j, 64)
			end
        end
    end
end

function update_death()
	death_timer -= 1 
	if death_timer == 0 then
		music(0, 4000)
		update_func = update_game
		player.x = 8
		player.y = 0
		camerax = -128
	end
end

function reset()
	death_timer = 30
    lives-=1
	update_func = update_death
    for g in all(bads) do
        g.x = g.o_x
        g.y = g.o_y
        g.show = true
        g.speed = -.5
    end
	projectiles = {}
end

function gravity()
    local dy = player.accel
    
	local x = player.x + player.sx
	local y = player.y + player.sy + dy
    if not check_move(x, y, player.w, player.h) then
		-- not inside a block
        player.y += dy
        player.grounded = false
    else
		-- check if they are not inside the roof, thus they are inside the ground
		if not (check_flag(x, y) or check_flag(x + player.w, y)) then
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
        
    end
    if player.can_move and player.x + dx > camerax then
        player.x += dx
    end
	
	if btnp(5) then
		-- projectiles
		shoot_projectile(player.x, player.y, player.flip_sprite_x)
	end
	
    check_death()
    move_opposition()
	move_projectiles()
	update_lava_geysers()
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
		flp = flp
	}
	add(projectiles, p)
end

function move_projectiles()
	for p in all(projectiles) do
		local dx = (p.flp and -2 or 2)
		-- check collision with map or outside of map
		if p.x + p.w < camerax or 
		   p.x - p.w > 1024 or
		   check_move(p.x + p.sx + dx, p.y + p.sy, p.w, p.h) then
			del(projectiles, p)
		else
			-- check sprite collision
			for g in all(bads) do
				if g.show then
					local collide = check_sprite_collision(p.x, p.y, p.sx, p.sy, p.w, p.h, g.x, g.y, g.sx, g.sy, g.w, g.h)
					if collide then
						del(projectiles, p)
						-- kill goomba
						g.show = false
						return
					end
				end
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
	Check if the two sprites are inside one another.
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
		spr(p.spr, p.x, p.y, 1, 1, p.flp)
	end
end

function check_end(x,y,w,h)
    return check_move(x,y,w,h,3)
end 

function check_death()
	local dead = false

	-- fell out of map
    if player.y > current_floor then
        dead = true
    end
	
	-- touched a lava geyser
	if not dead and hard_mode then
		local lgs = lava_geysers.sprites
		local i = 1
		while i <= #lgs and not dead do
			local lg = lgs[i]
			if check_sprite_collision(lg.x, lg.y, lava_geysers.sx, lava_geysers.sy, lava_geysers.w, lava_geysers.h, player.x, player.y, player.sx, player.sy, player.w, player.h) then
				dead = true
			end
			i += 1
		end
	end
	
	if dead then
		player.x = 8
        player.y = 0
        reset()
	end
end

function check_move(x,y,w,h,f)
    f = f or 0
    return check_flag(x+w, y, f) or
            check_flag(x, y+h, f) or
            check_flag(x, y, f) or
            check_flag(x+w, y+h, f)
end

function check_flag(x, y, f)
    return fget(mget(x/8,y/8),f)
end
function update_game_over()
--temp blank for the moment 
	music(-1, 500)
end
function draw_game()
    if lives > 0 then
        if player.x - 60 > camerax then
            camerax = player.x - 60
        end
        -- cameray = player.y - 60
        cameray = -20
        camera(camerax, cameray)
        cls(8)
        map(0,0,0,0,128,16)
        draw_bads()
	    draw_projectiles()
        spr(player.sprite, player.x, player.y, 1, 1, player.flip_sprite_x)
		for lg in all(lava_geysers.sprites) do
			spr(lava_geysers.spr_num, lg.x, lg.y, 1, 1, lava_geysers.flip) 
		end
        print("lives: ",camerax,cameray,7)
        for i=1,lives do
            spr(3, camerax + 18 + (8*i), cameray-1)
        end
    else
		update_func = update_game_over
        player.x = 0
        player.y = 0
        camera(0,0)
        cls()
        print("game ♥ over!!!",35,60,2)
    end
end
__gfx__
00000000bb2222bbbbbbbbbbbbbbbbbbbbbbbbbbbb2222bbbb2222bbbb2222bbbb2222bbbb2222bb000000000000000000000000000000000000000000000000
00000000b22f4fbbbbbb99bbbaaaaaabbbbb11bbb22f4fbbb22f4fbbb22f4fbbb2ffff2bb22f4fbb000000000000000000000000000000000000000000000000
00700700b22ffffbb999944bba0aa0abb1111ddbb22ffffbb22ffffbb22ffffbb24ff42bb22ffffb000000000000000000000000000000000000000000000000
00077000bb2fffbb9aaa444fbaaaaaab1cccddd6bb2fffbbbb2fffbbbb2fffbbbbffffbbbb2fffbb000000000000000000000000000000000000000000000000
00077000bbe09ebbb9aa4f44ba0aa0abb1ccd6ddbbe09ebbb0009ebbbbe0000fb0e9ee0bb0009e0f000000000000000000000000000000000000000000000000
00700700bb90f9fbb999944bba0000abb1111ddbbb90f9fbbf9aa9fbbb9aa9bbb09aa90bbf9aa9bb000000000000000000000000000000000000000000000000
00000000bbe9aebbbbbb99bbbaaaaaabbbbb11bbbbe9aebbbbe9aebbbbe9aebbbfe9aefbbbe9aebb000000000000000000000000000000000000000000000000
00000000bb22b22bbbbbbbbbbbbbbbbbbbbbbbbbbb00b00bbb0bb00bbb00b0bbb00bb00bbb0bb0bb000000000000000000000000000000000000000000000000
bbbbb5bb0000000000000000bb1111bbbb1111bbbb1111bbbb1111bbbb1111bb0000000000000000000000000000000000000000000000000000000000000000
bbbb565b0000000000000000b116c6bbb116c6bbb116c6bbb166661bb116c6bb0000000000000000000000000000000000000000000000000000000000000000
bb5566650000000000000000b116666bb116666bb116666bb1c66c1bb116666b0000000000000000000000000000000000000000000000000000000000000000
b56665650000000000000000b11666bbb11666bbb11666bbb166661bb11666bb0000000000000000000000000000000000000000000000000000000000000000
b50606650000000000000000b1dcddbbbcccddbbb1dcccc6bcddddcbbcccddc60000000000000000000000000000000000000000000000000000000000000000
b56666550000000000000000bbdc676bb6ddd76bbbddd7bbbcd77dcbb6ddd7bb0000000000000000000000000000000000000000000000000000000000000000
b556555b0000000000000000bbddd7bbbbddd7bbbbddd7bbb6d77d6bbbddd7bb0000000000000000000000000000000000000000000000000000000000000000
bb5555bb0000000000000000bb11b11bbb1bb11bbb11b1bbb11bb11bbb1bb1bb0000000000000000000000000000000000000000000000000000000000000000
bbbbb888cccbbbbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbb8888ccccbbbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbb88888cccccbbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bb888888ccccccbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bb888888ccccccbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbb88888cccccbbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbb8888ccccbbbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbb888cccbbbbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88888888566666655555565555555689babbabbb655555566555555665555556088888888888888888888800bbbbb99595bbbbbbbbbbb99595bbbbbb00000000
88888888656666566555555569555589bb9a9aba565555655655556556555565000888888888888888888009bbbb449059bbbbbbbbbbba9059bbbbbb00000000
88888888665665665555555559555555a999999a556556555565565555655655990008888888888888800099bbbbbba555bbbbbbbbbbb00555bbbbbb00000000
88888888666556665656555656568956bba999ab555665555550055555566555a9a9000888000888800099a8bbbb554589bbbbbbbbbbb54589bbbbbb00000000
88888888666556665555555555558955a999999a555665555550055555566555a989990088099080009a9aa8bbbbbbb595bbbbbbbbbbbbb595bbbbbb00000000
88888888665665665555555655589556ba9999aa556556555565565555655655888aa99a0009a00999a8aa88bbbb5955955abbbbbbbb5955955abbbb00000000
88888888656666565655655586556555bba999ab56555565565555655655556588888a980999899aaa888a88b4594a55584aa95bb4594a55584aa95b00000000
88888888566666655555555589555555bba99abb6555555665555556000000008888a9889aa88aa888888888b5894995555a9859b5894995555a985900000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055abbb58a955554955abbb58a955554900000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000005555bb555abbb94b5555bb555abbb94b00000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b45bbb5a9555bbbbb45bbb5a9555bbbb00000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bbbb555a5485bbbbbbbb555a5485bbbb00000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bbbb58845485bbbbbbbb58845485bbbb00000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bbbb9a4bb599bbbbbbbb9a4bb599bbbb00000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bbb588bbb589a5bbbbb588bbb589a5bb00000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bb4484bbbb4555bbbb4484bbbb4555bb00000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
04040404040404040404040404040404840404040404040404040404040404040404040404040404040404040404048404040414040404040404040404040404
04140404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404045454
04040414040414040414040404040404040404040404040414040404040404040404140404140404040404040404040404140404040404040404040404040404
04040404040404040404040404040404040404140404040404040404040404041404040414040404840404040404040404040404040404041404040404045454
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
04040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404
04040404040404048404040404040404040404040404040404040404040404840404040404040404040404040404040404040404040404040404040404040404
04040404040404040404040404040484040404040404040404040404040484040404040404040404140404040404040404040404040404040404040404040404
04040404040404040404040404040404040404040404040404040404040404040404040404040414040404040404040404040404040404040404040404040404
04040404040404041404140404040404040404040404040404040404040404040404040404040414140404040404040404040484040404040404040404040404
04040404040404040404040404040404040404040414040404041404040404040404040404140404040404040404840404040404040414040404041414141404
04040404040414040404040404040404040404040404040414040404040404040404040404041414140404040404040404040404040404040404040404040404
04040414041404040404040404040404040404041414040404040404040404040404041404040404041404040404040404040404041414040404040404040404
040404040404040404040404040404040404040404040404040404040404040404040404041414141404040404040404040404040404040404b4c40404040404
04040404010404044404040404040404040404141414044404040401040444040404040404040404040404040404040404010404141414044404010404010404
040444040401040401040404440404010404010404040404040404040404440401040404141414141404040404040404040404040404040404b5c50404040404
24242424242424242424242424040404042424242424242424242424243424243424040404040404040404140424242424242424242424242424242424242424
24242424242424242424242424242424242434242424240404242424242424242424242424242424242424242424242424242434242424242424242434242424
24342424243424243424242424040404042424242434242424342424242424242424040404040404040404040424243424242434242424242434242424242434
24242424342424242424242434242424242424243424240404242424342424343424342424242424242424242434242424242424242424243424243424242434
24242434242424243424243424444444442424243424242434242434242434242424444444444444444444444424242424242424343434242424243424242424
24242424242424342424342424242424342424242424244444242424242424242424242424342424242424242424243424242434243424242424242434243424
24242424342424242424242424444444442424242424242424242424242424243424444444444444444444444424242434242424242424242424242424242424
34242424242424242424242424242424242424242424244444242424342424242424242424242424342434242424242424242424242424242424243424242424
__gff__
0000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010101000909090000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
4040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
40404040404040404040484a4040404040404040404040404049404040484a4040404040404040404040404040404040404040494040404040484a40404040404040404040404040404040404040404040404040404040484a404040404040404040404040404040404040404040404040404040404940404040404040404040
404040484a40404040404040404040404040404040404040404040404040404040404040404040404040484a4040404040404040404040404040404040404040404040484a404040404040404040404040404040404040404040404049404040404040404049404040404040404040404040404040404040404040404040484a
40404040484a40404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040484a404040404040404041414140414141404040404040484a404040404040
40404040404040404040404940404040404040404040484a404040404040404040484a4040404040404040404040404040484a4040404040404040404040404040404040404040404040404040404040484a40404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
4040404040404040404040404040484a404040404040404040404040494040404040404040404940404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404141414040404040484a4040404040404040404040401040
4040404040404040404040404040404040404040404040404040404040404040404040401040404040404040404040104010401040404040404040484a40404040494040404040404040401040404040404940404040404040404040404040401040404040104040404040404040404040404040404040404040404040404545
4040404040404140414041404040404041404040494040404040404040404140404040404140404040404040404040414041404140404040404040404040404040404040404010404040404141414040404040404040404040404040414041404140404040414141404040404040404040404040404040414040494040404545
4040494040404040404040404040404040404040404040404040404040414140404040404040404040404040404040404040404040404040404040404040404040404041404041404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404041414040404040404546
4040404040404040404040404040404040404010404040404040404041414140404040404040444040404040404440404040404040444444404010404040404040404141404041414040404040404040444040404040404040404440404040404040404410404040404040404044404040404040404141414040404040104747
4242424242424242424342424243424242424242424342404042424243424242424243424242424342404042424342424242424242434242424242404042434242424242434242424242424342424242434242424040434242424243424242424243424242434242424243424242434242424040424342424243424242424242
4242424342424342424242434242434243424243424242404043424242424342424242424243424242404043424242424342424243424243424342404042424242434242424243424242424242434242424342424040424243424242424243424342424242424243424242424242434242434040424242434242424242434242
4243424242424242434242424242424242424242424342444442424342424242434242434342424242444442424342424242424242424342434242444442424342424242424242424243424242424342424243424444424242424242434242424242424342424242424243424242424242424444424242424242434242424242
4242424243424242424242424243424242424342424242444442424242434242424242424242424342444442424242424342424342424242424243444442434242424243424242424242424243424242424242424444424242434242424242434242424242424342424242424243424242424444424342424342424242424243
4040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
4040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404048404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404048404040
4040404040404040404040404040404040484040404040404040404040404040484040404040404040404040404040404040404040404040404840404040404040404040404040404040404040404040404040404040404040404040404040404040484040404040404040484040404040404040404040404040404040404040
4040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040484040404040404040404040404040404040404040404040404040404840404040404040404040404040
4040404840404040404040404140404040404040404040404048404040404040404040404040404041404040404040404040404040404040404040404040404040404040404040404040404040404040404140404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
4040404040404040404040404040404040404040404040404040404040404040404040404040414040404040404040404048404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404545
4040414040404040414040404040404040404040404040404040404040414040404040404140404040404040404040404040404040404040404040414040404040414040414040414040404040404041404040404040404040404040404040404140404140404040404040404040404140404040404040404140404040404545
4040404040404040404040404040404040404041404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040414140404040404546
4040404041404010404040404040404044404041404044401040404040404040404440401040404044444444404040404040404040404040444040404040444040404040401040404040404044404010404044404040404010404040404040401040404040404440404010404040404040404040404041414140404040404747
4242424242424242424242424040424242424242424242424242424040424242424242424243424242424242424242424242404042424243424242424242424242424242434242424242424242424242424242424242424242424240404242424242424242424242424242424242424242424040424342424242424242424242
4242424242424343424342424040424242424343424243424243424040424342424242434242424242434243424243424242404042424242424242434242424342424242424242424242424342424242424242424342424243424240404243424243424242424243424242424242434243424040424342424342424243424243
4242424342424242424243424444424243424243424242424342424444424243424342424242424342424242434242424342444442424242424342424242424242434242424342434242424242434242424342424243424242424244444242424242424243424242424242424342424242424444424242424243424242424342
4342424242424242424242424444424242424242424242424242424444424242424242424242424242424242424242424242444442424242424242424242424242424242424242424242424242424242424242424242424242424244444242424242424242424242434242424242424242424444424242424242424242424242
4040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
4040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404840404040404040
4040404040404040484040404040404040404040404040404040404048404040404040404040404840404040404040404040404040404040404040404048404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
4840404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404048404040404040404040404040404040404040404040404040404040404040484040404040404040404040404040404040
4040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040414040414040404040404040404040404040404048404040404040404040404040404040404840404040404040404040404040404040404040404040404040404040404040404040404040
__sfx__
001000002850022500295502a55029550285501950026550155002555024550275002355021550205501d5501c5500e5000e50000500005000050000500005000050000500005000050000500005000050000500
00100020220100e0100c0100c0500c0500d050180501a0501c0501d0501f05021050230502a050320502c0501205014050160500c0500e0501005011050130501505017050190501b050190501b0501e05020050
001000000c5400c54004540155401f54016540115400f5400f540145401d540205401c540165400e540075400f540165401d54023540275402954027540215401b54012540105400c5400c5400a5400c5400a540
00200000106100f6100e6100d6100c61012610186101e6102261024610226101f6101c61019610156100f6100c61009610076100a6100e610116101461016610186101a6101761015610136100e6100a61009610
011000000f7400d740007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700000000000000000000000000000000000000000000000000000000000000
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
02 02424343