pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
lives = 0
camerax = -128
music_on = false
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
	jump_hold = 0
}
sprite_x = 0
sprite_y = 0
hard_mode = false
bads = {}
projectiles = {}
flag_x = 0
flag_max_y = 0
level_end = false
update_fuc = nil
draw_func = nil
input_delay = 0

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
        input_delay = 0
        update_fuc = update_game
        draw_func = draw_game
    end
end

function draw_char_select()
    cls() 
    print("select a character",32,0,7)
    sspr(0,16, 8, 8, 16, 48, 8*4, 8*4) 
    sspr(sprite_x, sprite_y, 8, 8, 48, 48, 8*4, 8*4, player.flip_sprite_x)
    sspr(8,16, 8, 8, 80, 48, 8*4, 8*4) 
end

function new_goomba(x,y,speed,s_num)
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
				
			-- Check if the player touches a goomba
			if check_sprite_collision(player.x, player.y, player.sx, player.sy, player.w, player.h, g.x, g.y, g.sx, g.sy, g.w, g.h) then
				-- The player touched a goomba
				player.x = 8
				player.y = 0
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
    -- draw_func = draw_game
    -- update_func = update_game
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
                add(bads,new_goomba(i,j,.5,sprite))
                mset(i,j,64)
            end
            if fget(sprite, 4) then
                flag_x = i*8 + 5
                flag_max_y = j*8 + 5
            end
        end
    end
end

function reset()
    camerax = -128
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
    if player.y > 120 then
        lives-=1
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
        print("lives: ",camerax,cameray,7)
        for i=1,lives do
            spr(3, camerax + 18 + (8*i), cameray-1)
        end
    else
        player.x = 0
        player.y = 0
        camera(0,0)
        cls()
        print("game ♥ over!!!",35,60,2)
    end
end
__gfx__
00000000bb9999bbbbbbbbbbbbbbbbbbbbbbbbbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000b99f4fbbbbbb99bbbaaaaaabbbbb11bb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700b99ffffbb999944bba0aa0abb1111ddb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000bb9fffbb9aaa444fbaaaaaab1cccddd60000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000bb2a22bbb9aa4f44ba0aa0abb1ccd6dd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700bb2af2fbb999944bba0000abb1111ddb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000bb2222bbbbbb99bbbaaaaaabbbbb11bb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000bb99b99bbbbbbbbbbbbbbbbbbbbbbbbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbabb0000000000000000bb1111bb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbb29ab0000000000000000b116c6bb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bb22499a0000000000000000b116666b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
b29994420000000000000000b11666bb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
b20909920000000000000000b1dcddbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
249999420000000000000000bbdc6d6b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
b249442b0000000000000000bbddddbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bb2222bb0000000000000000bb11b11b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
88888888566666655555565555555689babbabbb6555555665555556655555560888888888888888888888000000000000000000000000000000000000000000
88888888656666566555555569555589bb9a9aba5655556556555565565555650008888888888888888880090000000000000000000000000000000000000000
88888888665665665555555559555555a999999a5565565555655655556556559900088888888888888000990000000000000000000000000000000000000000
88888888666556665656555656568956bba999ab555665555550055555566555a9a9000888000888800099a80000000000000000000000000000000000000000
88888888666556665555555555558955a999999a555665555550055555566555a989990088099080009a9aa80000000000000000000000000000000000000000
88888888665665665555555655589556ba9999aa556556555565565555655655888aa99a0009a00999a8aa880000000000000000000000000000000000000000
88888888656666565655655586556555bba999ab56555565565555655655556588888a980999899aaa888a880000000000000000000000000000000000000000
88888888566666655555555589555555bba99abb6555555665555556000000008888a9889aa88aa8888888880000000000000000000000000000000000000000
__gff__
0000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010101000101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
4040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
40404040404040404040484a4040404040404040404040404049404040484a4040404040404040404040404040404040404040494040404040484a40404040404040404040404040404040404040404040404040404040484a404040404040404040404040404040404040404040404040404040404940404040404040404040
404040484a40404040404040404040404040404040404040404040404040404040404040404040404040484a4040404040404040404040404040404040404040404040484a404040404040404040404040404040404040404040404049404040404040404049404040404040404040404040404040404040404040404040484a
40404040484a40404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040484a404040404040404041414140414141404040404040484a404040404040
40404040404040404040404940404040404040404040484a404040404040404040484a4040404040404040404040404040484a4040404040404040404040404040404040404040404040404040404040484a40404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
4040404040404040404040404040484a404040404040404040404040494040404040404040404940404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404141414040404040484a4040404040404040404040404040
4040404040404040404040404040404040404040404040404040404040404040404040401040404040404040404040404040404040404040404040484a40404040494040404040404040404040404040404940404040404040404040404040404040404040404040404040404040404040404040404040404040404040404545
4040404040404140414041404040404041404040494040404040404040404140404040404140404040404040404040414041404140404040404040404040404040404040404040404040404141414040404040404040404040404040414041404140404040414141404040404040404040404040404040414040494040404545
4040494040404040404040404040404040404040404040404040404040414140404040404040404040404040404040404040404040404040404040404040404040404041404041404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404041414040404040404546
4040404040404040404040404040404040404010404040404040404041414140404040404040444040404040404440404040404040444444404040404040404040404141404041414040404040404040444040404040404040404440404040404040404440404040404040404044404040404040404141414040404040404747
4242424242424242424342424243424242424242424342404042424243424242424243424242424342404042424342424242424242434242424242404042434242424242434242424242424342424242434242424040434242424243424242424243424242434242424243424242434242424040424342424243424242424242
4242424342424342424242434242434243424243424242404043424242424342424242424243424242404043424242424342424243424243424342404042424242434242424243424242424242434242424342424040424243424242424243424342424242424243424242424242434242434040424242434242424242434242
4243424242424242434242424242424242424242424342444442424342424242434242434342424242444442424342424242424242424342434242444442424342424242424242424243424242424342424243424444424242424242434242424242424342424242424243424242424242424444424242424242434242424242
4242424243424242424242424243424242424342424242444442424242434242424242424242424342444442424242424342424342424242424243444442434242424243424242424242424243424242424242424444424242434242424242434242424242424342424242424243424242424444424342424342424242424243
__sfx__
001000002850022500295502a55029550285501950026550155002555024550275002355021550205501d5501c5500e5000e50000500005000050000500005000050000500005000050000500005000050000500
00100020220100e0100c0100c0500c0500d050180501a0501c0501d0501f05021050230502a050320502c0501205014050160500c0500e0501005011050130501505017050190501b050190501b0501e05020050
001000000c5400c54004540155401f54016540115400f5400f540145401d540205401c540165400e540075400f540165401d54023540275402954027540215401b54012540105400c5400c5400a5400c5400a540
00200000106100f6100e6100d6100c61012610186101e6102261024610226101f6101c61019610156100f6100c61009610076100a6100e610116101461016610186101a6101761015610136100e6100a61009610
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
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000365000600006000060000600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
02 02424343

