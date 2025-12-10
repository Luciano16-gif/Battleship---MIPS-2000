.data 
					# Español fecha de creacion aprox junio
					# Hola que tal, antes de que revises deberias saber un par de cosas
					# primero que si, esto tiene demasiados pero que demasiados comentarios
					# se viene semana de parciales y todo esto se me va a olvidar en los 
					# proximos dias (probablemente) tambien haciendolo me frustre en un 
					# momento por exceso de informacion y empece a comentar todo a lo
					# desgraciado para que no se me olvide
					# Para la logica de la IA inteligente (mas inteligente que chatgpt, confia)
					# tendras que chequear las cosas del player 2
					# casi toda la logica era la misma asi que la decidi reutilizar para ahorrar
					# tiempo y complejidad
					# Los comentarios estan en español ya que la clase era en español.

					# Como jugar
					# Ve a tools y activa Bitmap display
					# Pixel width y height to 16
					# Display width 256, Display height 512
					# Base adress for display 0x10010000 (static data)
					
					# Controles
					# Moverse: awsd
					# Colocar barcos y atacar: e
					# rotar barcos: r

display: .space 2048                    
input: .space 2                         # Buffer para input del usuario (2 caracteres)
current_ship: .word 0                   # Índice del barco actual (0=portaaviones, 1=acorazado, 2=submarino, 3=fragata)
ship_sizes: .word 5, 4, 3, 2            # Tamaños de los barcos en orden
orientation: .word 0                    # 0=horizontal, 1=vertical
game_mode: .word 0                      # 1=PvP, 2=PvE
invalid_msg: .asciiz "\nPosicion invalida\n"   # Mensaje de error

# VARIABLES PARA PVP
current_player: .word 1                 # Jugador actual (1 o 2)
game_phase: .word 0                     # 0=colocación, 1=ataque
attack_cursor: .word 0                  # Posición del cursor de ataque
attempts_left: .word 3                  # Intentos restantes en el turno (PvP)
player1_score: .word 0                  # Puntuación jugador 1
player2_score: .word 0                  # Puntuación jugador 2
saved_pixel_color: .word 0              # Color del pixel donde está el cursor

# VARIABLES PARA IA INTELIGENTE (mas facil hubiera sido entrenar un transformer para que sepa jugar esto)
ai_mode: .word 0                        # 0=hunting (aleatorio), 1=targeting (dirigido)
ai_target_pos: .word 0                  # Posición del primer impacto encontrado
ai_direction: .word 0                   # Dirección actual (0=arriba, 1=derecha, 2=abajo, 3=izquierda)
ai_original_hit: .word 0                # Posición original del primer hit del barco
ai_steps_in_direction: .word 0          # Pasos dados en dirección actual

# MAPAS DE BARCOS - Arrays para trackear posiciones con ID de barco
# Valores en el mapa: 0=agua, 1=portaaviones, 2=acorazado, 3=submarino, 4=fragata
player1_ship_map: .space 2048           # Mapa de barcos del jugador 1 
player2_ship_map: .space 2048           # Mapa de barcos del jugador 2 y de la cpu

# Arrays para tracking de barcos
player1_ships_health: .word 5, 4, 3, 2  # Salud actual de cada barco del jugador 1
player2_ships_health: .word 5, 4, 3, 2  # Salud actual de cada barco del jugador 2

# MENSAJES DEL SISTEMA
menu_title: .asciiz "\n=== BATTLESHIP ===\n"
menu_option1: .asciiz "1. Jugador vs Jugador (PvP)\n"
menu_option2: .asciiz "2. Jugador vs CPU (PvE)\n"
menu_prompt: .asciiz "Selecciona una opcion (1 o 2): "
invalid_option: .asciiz "Opcion invalida! Presiona 1 o 2.\n"
jump: .asciiz "\n"

# MENSAJES DE CONFIGURACIÓN
player1_msg: .asciiz "\n=== JUGADOR 1 (Tablero Superior) - Coloca tus barcos ===\n"
player2_msg: .asciiz "\n=== JUGADOR 2 (Tablero Inferior) - Coloca tus barcos ===\n"
ai_placing_msg: .asciiz "\n=== CPU colocando barcos... ===\n"
game_setup_complete: .asciiz "\n=== CONFIGURACION COMPLETA ===\nPresiona cualquier tecla para comenzar la batalla!\n"

# MENSAJES DE ATAQUE
attack_phase_msg: .asciiz "\n=== FASE DE ATAQUE ===\n"
player1_attack_msg: .asciiz "\nJUGADOR 1 ataca el tablero inferior\n"
player2_attack_msg: .asciiz "\nJUGADOR 2 ataca el tablero superior\n"
hit_msg: .asciiz "\n¡IMPACTO! Dispara de nuevo.\n"
miss_msg: .asciiz "\n¡FALLO! "
attempts_msg: .asciiz "Intentos restantes: "
ship_sunk_msg: .asciiz "\n¡HUNDIDO!\n"
player1_wins_msg: .asciiz "\n¡GANA JUGADOR 1!\n"
player2_wins_msg: .asciiz "\n¡GANA JUGADOR 2!\n"
cpu_wins_msg: .asciiz "\n¡GANA LA CPU!\n"
score_msg: .asciiz "Puntuacion: "
game_over_msg: .asciiz "\nGAME OVER\n"
area_attack_msg: .asciiz "\n*** ¡ATAQUE EN AREA! *** (3x3)\n"

# MENSAJES DE PUNTUACIÓN
player1_score_msg: .asciiz "Jugador 1: "
player2_score_msg: .asciiz "Jugador 2: "
cpu_score_msg: .asciiz "CPU: "
final_scores_title: .asciiz "\n=== PUNTUACIONES FINALES ===\n"

# COLORES DEL JUEGO
white: .word 0xFFFFFF                   # Blanco para fallos
green: .word 0x00FF00                   # Verde para cursor de ataque
red: .word 0xFF0000                     # Rojo para impactos
purple: .word 0x800080                  # Morado para línea separadora

.text
# ============= MENÚ PRINCIPAL =============
main_menu:
    # Mostrar título del juego
    li $v0, 4
    la $a0, menu_title
    syscall
    
    # Mostrar opciones
    li $v0, 4
    la $a0, menu_option1
    syscall
    
    li $v0, 4
    la $a0, menu_option2
    syscall
    
    # Mostrar prompt
    li $v0, 4
    la $a0, menu_prompt
    syscall

menu_input:
    # Leer input del usuario
    li $v0, 8                # syscall para leer string
    la $a0, input            # dirección del buffer
    li $a1, 2                # máximo 2 caracteres
    syscall
    
    lb $t5, input            # cargar primer carácter del input
    
    li $v0, 4
    la $a0, jump
    syscall
    
    # Verificar opciones válidas
    beq $t5, 0x31, select_pvp    # '1' = PvP
    beq $t5, 0x32, select_pve    # '2' = PvE
    
    # Opción inválida
    li $v0, 4
    la $a0, invalid_option
    syscall
    b menu_input             # pedir input nuevamente

select_pvp:
    li $t6, 1                # establecer modo PvP
    sw $t6, game_mode        # guardar en memoria también
    b start_game             # ir al juego

select_pve:
    li $t6, 2                # establecer modo PvE  
    sw $t6, game_mode        # guardar en memoria también
    b start_game             # ir al juego

# ============= INICIALIZACIÓN DEL JUEGO =============
start_game:
    # Mostrar mensaje del jugador actual
    lw $s0, current_player
    beq $s0, 1, show_player1_msg
    
show_player2_msg:
    li $v0, 4
    la $a0, player2_msg
    syscall
    
    # Esconder barcos del jugador 1 cuando jugador 2 va a colocar
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    jal hide_player1_ships
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    
    b init_registers


show_player1_msg:
    li $v0, 4
    la $a0, player1_msg
    syscall
    
    # Mostrar barcos del jugador 1 cuando va a colocar o es su turno
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    jal show_player1_ships
    lw $ra, 0($sp)
    addi $sp, $sp, 4


init_registers:
    # Colores principales del juego
    li $t0, 0x0000ff     # azul (color base de los tableros)
    li $t1, 0            # contador para loops de pintado
    li $t2, 0xff0000     # rojo (color de la línea separadora)
    li $t3, 0xFFFF00     # amarillo (color del barco en preview)
    li $t7, 0x808080     # gris (color de barcos colocados permanentemente)
    
    # Establecer posición inicial del cursor según el jugador
    lw $s0, current_player
    beq $s0, 1, set_player1_cursor
    
set_player2_cursor:
    li $t4, 1088         # posición inicial para jugador 2 (después de la línea roja)
    b continue_init

set_player1_cursor:
    li $t4, 64           # posición inicial para jugador 1 (segunda fila del tablero superior)
    
continue_init:
    # Resetear barco actual y orientación para el nuevo jugador
    sw $zero, current_ship
    sw $zero, orientation

# ============= PINTADO INICIAL DEL TABLERO =============
    # Solo pintar el tablero completo si es el jugador 1
    lw $s0, current_player
    bne $s0, 1, skip_initial_paint

# Pintar todo el display de azul primero
loop_all_blue:
	sw $t0, display($t1)     # pintar pixel azul en posición $t1
	addi $t1, $t1, 4         # avanzar a siguiente pixel (4 bytes)
	beq $t1, 2048, paint_separator   # si llegamos al final, ir a pintar separador
	b loop_all_blue          # continuar pintando azul

# Pintar línea separadora morada en el medio (2 filas de alto)
paint_separator:
	move $s1, $t2            # guardar valor original de $t2 (rojo)
	li $t2, 0x800080         # cambiar temporalmente a morado
	li $t1, 960              # empezar en fila 15 (15 × 64 = 960)
	
separator_row1:              # primera fila del separador
	sw $t2, display($t1)     # pintar pixel morado
	addi $t1, $t1, 4         # siguiente pixel
	beq $t1, 1024, separator_row2   # si completamos fila 15, ir a fila 16
	b separator_row1
	
separator_row2:              # segunda fila del separador
	sw $t2, display($t1)     # pintar pixel morado
	addi $t1, $t1, 4         # siguiente pixel
	beq $t1, 1088, restore_t2   # si completamos fila 16, restaurar $t2
	b separator_row2

restore_t2:
	move $t2, $s1            # restaurar valor original de $t2 (rojo)
	b skip_initial_paint

skip_initial_paint:
	# Pintar el primer barco (portaaviones) en preview
	jal paint_current_ship
	
# ============= LOOP PRINCIPAL DE INPUT =============
input_loop:
	# Leer input del usuario
	li $v0, 8                # syscall para leer string
	la $a0, input            # dirección del buffer
	li $a1, 2                # máximo 2 caracteres
	syscall
	
	lb $t5, input            # cargar primer carácter del input
	
	# Verificar qué tecla presionó
	beq $t5, 0x77, up        # 'w' = mover arriba
	beq $t5, 0x61, left      # 'a' = mover izquierda
	beq $t5, 0x73, down      # 's' = mover abajo
	beq $t5, 0x64, right     # 'd' = mover derecha
	beq $t5, 0x65, place     # 'e' = colocar barco
	beq $t5, 0x72, try_rotate # 'r' = intentar rotar barco
	beq $t5, 0x7A, exit      # 'z' = salir del programa
	
	b input_loop             # si no es ninguna tecla válida, repetir

# ============= VERIFICAR SI SE PUEDE ROTAR =============
try_rotate:
	# Verificar si posición actual es válida para rotación
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal is_valid_position    # usar lógica existente de validación
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	beq $v0, 0, input_loop   # si no es válida (sobre gris), ignorar rotación
	b rotate                 # si es válida, proceder con rotación normal

# ============= FUNCIONES DE MOVIMIENTO =============
up:
	# Verificar si TODO el barco puede moverse hacia arriba
	addi $sp, $sp, -4        # guardar $ra en stack
	sw $ra, 0($sp)
	jal can_move_up          # verificar si el movimiento es válido
	lw $ra, 0($sp)           # restaurar $ra
	addi $sp, $sp, 4
	
	beq $v0, 0, input_loop   # si $v0=0 (no válido), no mover
	
	jal clear_current_ship   # borrar barco de posición actual
	addi $t4, $t4, -64       # mover cursor arriba (1 fila = 64 bytes)
	jal paint_current_ship   # pintar barco en nueva posición
	b input_loop

left:
	# Verificar si TODO el barco puede moverse hacia la izquierda
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal can_move_left
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	beq $v0, 0, input_loop
	
	jal clear_current_ship   # borrar barco actual
	addi $t4, $t4, -4        # mover cursor izquierda (1 pixel = 4 bytes)
	jal paint_current_ship   # pintar en nueva posición
	b input_loop

right:
	# Verificar si TODO el barco puede moverse hacia la derecha
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal can_move_right
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	beq $v0, 0, input_loop
	
	jal clear_current_ship   # borrar barco actual
	addi $t4, $t4, 4         # mover cursor derecha
	jal paint_current_ship   # pintar en nueva posición
	b input_loop

down:
	# Verificar si TODO el barco puede moverse hacia abajo
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal can_move_down
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	beq $v0, 0, input_loop
	
	jal clear_current_ship   # borrar barco actual
	addi $t4, $t4, 64        # mover cursor abajo
	jal paint_current_ship   # pintar en nueva posición
	b input_loop

# ============= FUNCIÓN DE ROTACIÓN =============
rotate:
	jal clear_current_ship   # borrar barco actual
	
	# Cambiar orientación (0→1 o 1→0)
	lw $s0, orientation
	xori $s0, $s0, 1         # XOR con 1 para alternar bit
	sw $s0, orientation      # guardar nueva orientación
	
	# Verificar si la nueva orientación cabe en la posición actual
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal is_valid_position    # verificar si cabe con nueva orientación
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	beq $v0, 0, revert_rotation   # si no cabe, revertir rotación
	
	jal paint_current_ship   # si cabe, pintar con nueva orientación
	b input_loop

revert_rotation:
	# La rotación no es válida, volver a orientación anterior
	lw $s0, orientation
	xori $s0, $s0, 1         # revertir el cambio
	sw $s0, orientation
	jal paint_current_ship   # repintar con orientación original
	b input_loop

# ============= FUNCIÓN DE COLOCACIÓN =============
place:
	# Verificar que la posición actual sea válida ANTES de colocar
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal is_valid_position    # verificar que no haya colisión
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	beq $v0, 0, place_invalid # si no es válida, mostrar error y no colocar
	
	# Si llegamos aquí, la posición es válida
	jal place_current_ship
	
	# Avanzar al siguiente barco
	lw $s0, current_ship
	addi $s0, $s0, 1
	sw $s0, current_ship
	
	blt $s0, 4, setup_next_ship  # Si aún quedan barcos, continuar
	
	# El jugador actual terminó de colocar todos sus barcos
	jal player_finished_placing

setup_next_ship:
	b input_loop

place_invalid:
	# Mostrar mensaje de error y NO colocar el barco
	li $v0, 4
	la $a0, invalid_msg
	syscall
	b input_loop             # volver al input sin colocar nada

# ============= FUNCIÓN CUANDO UN JUGADOR TERMINA =============
player_finished_placing:
    # Verificar modo de juego
    lw $s0, game_mode
    beq $s0, 2, ai_place_ships   # Si es PvE, colocar barcos de IA
    
    # Modo PvP - verificar qué jugador terminó
    lw $s0, current_player
    beq $s0, 2, both_players_done  # Si el jugador 2 terminó, ambos han colocado
    
    # El jugador 1 terminó, cambiar al jugador 2
    li $s0, 2
    sw $s0, current_player
    
    # Esconder barcos del jugador 1 antes de que el jugador 2 coloque
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    jal hide_player1_ships
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    
    # Ir a start_game para que el jugador 2 coloque sus barcos
    b start_game

ai_place_ships:
	# Mostrar mensaje de que la IA está colocando barcos
	li $v0, 4
	la $a0, ai_placing_msg
	syscall
	
	# Llamar función para colocar barcos automáticamente
	jal place_ai_ships
	
	# Continuar al setup completo
	b both_players_done

both_players_done:
	# Ambos jugadores han colocado sus barcos
	li $v0, 4
	la $a0, game_setup_complete
	syscall
	
	# Esperar input
	li $v0, 8
	la $a0, input
	li $a1, 2
	syscall
	
	# Cambiar a fase de ataque
	li $s0, 1
	sw $s0, game_phase       # game_phase = 1 (ataque)
	
	# Resetear al jugador 1 para comenzar ataques
	li $s0, 1
	sw $s0, current_player
	
	# Iniciar fase de ataque
	b start_attack_phase

# ============= COLOCACIÓN AUTOMÁTICA DE BARCOS DE LA IA =============
# Función principal que coloca todos los barcos de la IA de forma aleatoria
place_ai_ships:
	# Guardar registros
	addi $sp, $sp, -16
	sw $s0, 0($sp)           # índice de barco actual
	sw $s1, 4($sp)           # contador de intentos
	sw $ra, 8($sp)
	sw $t0, 12($sp)          # preservar $t0
	
	li $s0, 0                # empezar con el primer barco (portaaviones)
	
place_ai_loop:
	bge $s0, 4, place_ai_done    # si ya colocamos los 4 barcos, terminar
	
	# Intentar colocar el barco actual hasta conseguir posición válida
	li $s1, 0                # contador de intentos (para evitar loop infinito)
	
try_place_current_ai_ship:
	bgt $s1, 1000, place_ai_error    # evitar loop infinito después de 1000 intentos
	
	# Colocar el barco actual
	move $a0, $s0            # pasar índice del barco
	jal try_place_ai_ship
	
	beq $v0, 1, ai_ship_placed   # si se colocó exitosamente, continuar
	
	addi $s1, $s1, 1         # incrementar intentos
	b try_place_current_ai_ship
	
ai_ship_placed:
	addi $s0, $s0, 1         # avanzar al siguiente barco
	b place_ai_loop
	
place_ai_done:
	# Restaurar registros
	lw $s0, 0($sp)
	lw $s1, 4($sp)
	lw $ra, 8($sp)
	lw $t0, 12($sp)
	addi $sp, $sp, 16
	jr $ra

place_ai_error:
	# Si llegamos aquí, hay un error en la lógica (no debería pasar)
	li $v0, 4
	la $a0, invalid_msg
	syscall
	b place_ai_done

# ============= INTENTAR COLOCAR UN BARCO ESPECÍFICO DE LA IA =============
try_place_ai_ship:
	# $a0 = índice del barco (0-3)
	addi $sp, $sp, -32
	sw $s0, 0($sp)           # índice del barco
	sw $s1, 4($sp)           # posición aleatoria
	sw $s2, 8($sp)           # orientación aleatoria
	sw $s3, 12($sp)          # tamaño del barco
	sw $s4, 16($sp)          # contador para colocación
	sw $s5, 20($sp)          # ID del barco (índice + 1)
	sw $s6, 24($sp)          # posición actual durante colocación
	sw $ra, 28($sp)
	
	move $s0, $a0            # guardar índice del barco
	
	# Obtener tamaño del barco
	sll $s3, $s0, 2          # multiplicar índice por 4
	lw $s3, ship_sizes($s3)  # obtener tamaño
	
	# Generar posición aleatoria en el tablero inferior
	li $v0, 42               # syscall para random int range
	li $a0, 0                # generator ID
	li $a1, 16               # rango 0-15 (16 columnas)
	syscall
	move $s7, $a0            # $s7 = columna aleatoria (0-15)
	
	li $v0, 42
	li $a0, 0
	li $a1, 15               # rango 0-14 (15 filas en tablero inferior)
	syscall
	addi $a0, $a0, 17        # convertir a fila 17-31 (después de separador)
	move $t9, $a0            # $t9 = fila aleatoria (17-31)
	
	# Convertir (columna, fila) a offset del display
	sll $s1, $t9, 6          # fila * 64
	sll $t8, $s7, 2          # columna * 4
	add $s1, $s1, $t8        # posición = (fila * 64) + (columna * 4)
	
	# Generar orientación aleatoria
	li $v0, 42
	li $a0, 0
	li $a1, 2                # rango 0-1
	syscall
	move $s2, $a0            # $s2 = orientación (0=horizontal, 1=vertical)
	
	# Validar si esta posición y orientación son válidas
	move $a0, $s1            # posición
	move $a1, $s2            # orientación
	move $a2, $s3            # tamaño del barco
	jal validate_ai_position
	
	beq $v0, 0, ai_placement_failed   # si no es válida, fallar
	
	# Si llegamos aquí, la posición es válida - colocar el barco
	move $s6, $s1            # posición inicial
	move $s4, $s3            # contador = tamaño del barco
	addi $s5, $s0, 1         # ID del barco = índice + 1
	
ai_place_loop:
	beq $s4, 0, ai_placement_success   # si contador = 0, terminamos
	
	# Guardar ID del barco en el mapa
	sw $s5, player2_ship_map($s6)
	
	addi $s4, $s4, -1        # decrementar contador
	beq $s4, 0, ai_placement_success   # si ya terminamos, éxito
	
	# Mover a siguiente posición según orientación
	beq $s2, 0, ai_place_horizontal
	addi $s6, $s6, 64        # vertical: siguiente fila
	b ai_place_loop
	
ai_place_horizontal:
	addi $s6, $s6, 4         # horizontal: siguiente columna
	b ai_place_loop
	
ai_placement_success:
	li $v0, 1                # retornar éxito
	b ai_place_ship_done
	
ai_placement_failed:
	li $v0, 0                # retornar fallo
	
ai_place_ship_done:
	# Restaurar registros
	lw $s0, 0($sp)
	lw $s1, 4($sp)
	lw $s2, 8($sp)
	lw $s3, 12($sp)
	lw $s4, 16($sp)
	lw $s5, 20($sp)
	lw $s6, 24($sp)
	lw $ra, 28($sp)
	addi $sp, $sp, 32
	jr $ra

# ============= VALIDAR POSICIÓN PARA IA =============
validate_ai_position:
	# $a0 = posición inicial, $a1 = orientación, $a2 = tamaño del barco
	addi $sp, $sp, -24
	sw $s0, 0($sp)           # posición actual
	sw $s1, 4($sp)           # orientación
	sw $s2, 8($sp)           # tamaño restante
	sw $s3, 12($sp)          # valor en mapa
	sw $s4, 16($sp)          # cálculos temporales
	sw $ra, 20($sp)
	
	move $s0, $a0            # posición inicial
	move $s1, $a1            # orientación
	move $s2, $a2            # tamaño del barco
	
validate_ai_loop:
	beq $s2, 0, validate_ai_success   # si verificamos todo, éxito
	
	# Verificar límites del tablero inferior (1088-2047)
	blt $s0, 1088, validate_ai_fail   # debe estar después de línea roja
	bge $s0, 2048, validate_ai_fail   # no puede salirse del tablero
	
	# Verificar bordes según orientación
	beq $s1, 1, validate_ai_collision
	
	# Para orientación horizontal: verificar borde derecho
	andi $s4, $s0, 63        # posición % 64 (posición dentro de la fila)
	addi $s4, $s4, 4         # siguiente posición
	beq $s4, 64, validate_ai_edge   # si llegaría al borde
	b validate_ai_collision
	
validate_ai_edge:
	beq $s2, 1, validate_ai_collision   # si es el último pixel, ok
	b validate_ai_fail                  # si no, se saldría del borde
	
validate_ai_collision:
	# Verificar que no haya otro barco ya colocado
	lw $s3, player2_ship_map($s0)
	bne $s3, 0, validate_ai_fail       # si hay algo (ID != 0), colisión
	
	# Mover a siguiente posición
	beq $s1, 0, validate_ai_horizontal
	addi $s0, $s0, 64        # vertical: siguiente fila
	b validate_ai_continue
	
validate_ai_horizontal:
	addi $s0, $s0, 4         # horizontal: siguiente columna
	
validate_ai_continue:
	addi $s2, $s2, -1        # decrementar tamaño restante
	b validate_ai_loop
	
validate_ai_success:
	li $v0, 1                # retornar éxito
	b validate_ai_done
	
validate_ai_fail:
	li $v0, 0                # retornar fallo
	
validate_ai_done:
	# Restaurar registros
	lw $s0, 0($sp)
	lw $s1, 4($sp)
	lw $s2, 8($sp)
	lw $s3, 12($sp)
	lw $s4, 16($sp)
	lw $ra, 20($sp)
	addi $sp, $sp, 24
	jr $ra

# ============= FASE DE ATAQUE =============
start_attack_phase:
	# Mostrar mensaje de fase de ataque
	li $v0, 4
	la $a0, attack_phase_msg
	syscall
	
	# ASEGURAR QUE LAS LÍNEAS SEPARADORAS SEAN MORADAS
	jal repaint_separator_lines
	
	# Verificar modo de juego
	lw $s0, game_mode
	beq $s0, 2, pve_attack_setup    # Si es PvE, ir directo a setup PvE
	
	# Resetear intentos para PvP
	li $s0, 3
	sw $s0, attempts_left

show_attack_turn:
	# ASEGURAR QUE LAS LÍNEAS SEPARADORAS SEAN MORADAS
	jal repaint_separator_lines
	
	# Para PvE, siempre es el jugador 1 quien ataca
	lw $s0, game_mode
	beq $s0, 2, pve_player_attacks
	
	# Mostrar de quién es el turno (PvP)
	lw $s0, current_player
	beq $s0, 1, show_player1_attack
	
show_player2_attack:
	li $v0, 4
	la $a0, player2_attack_msg
	syscall
	
	# NUEVO: Esconder barcos del jugador 1 (tablero superior)
	jal hide_player1_ships
	
	# Jugador 2 ataca tablero superior, cursor empieza arriba
	li $s0, 64
	sw $s0, attack_cursor
	b init_attack_cursor
	
show_player1_attack:
    	li $v0, 4
    	la $a0, player1_attack_msg
   	 syscall
    
    	# Mostrar barcos propios del jugador 1 cuando es su turno de atacar
    	addi $sp, $sp, -4
    	sw $ra, 0($sp)
    	jal show_player1_ships
    	lw $ra, 0($sp)
    	addi $sp, $sp, 4
    
    	# Esconder barcos del jugador 2 (tablero inferior)
    	addi $sp, $sp, -4
    	sw $ra, 0($sp)
    	jal hide_player2_ships
    	lw $ra, 0($sp)
    	addi $sp, $sp, 4
    
    	# Jugador 1 ataca tablero inferior, cursor empieza abajo
    	li $s0, 1088
    	sw $s0, attack_cursor
    	b init_attack_cursor


pve_player_attacks:
	# En PvE, siempre muestra mensaje del jugador 1
	li $v0, 4
	la $a0, player1_attack_msg
	syscall
	
	# Esconder barcos de la IA (no mostrar barcos del jugador 2)
	jal hide_player2_ships
	
	# Jugador ataca tablero inferior (donde está la IA)
	li $s0, 1088
	sw $s0, attack_cursor
	b init_attack_cursor

pve_attack_setup:
	# ASEGURAR QUE LAS LÍNEAS SEPARADORAS SEAN MORADAS
	jal repaint_separator_lines
	
	# En PvE, siempre muestra mensaje del jugador 1
	li $v0, 4
	la $a0, player1_attack_msg
	syscall
	
	# Esconder barcos de la IA (no mostrar barcos del jugador 2)
	jal hide_player2_ships
	
	# Jugador ataca tablero inferior (donde está la IA)
	li $s0, 1088
	sw $s0, attack_cursor

init_attack_cursor:
	# Guardar el color original del pixel inicial
	lw $s0, attack_cursor
	lw $s1, display($s0)
	sw $s1, saved_pixel_color
	
	# Pintar cursor de ataque verde (tanto PvP como PvE)
	lw $s1, green
	sw $s1, display($s0)

# ============= LOOP DE ATAQUE =============
attack_loop:
	# Leer input del usuario
	li $v0, 8
	la $a0, input
	li $a1, 2
	syscall
	
	lb $t5, input
	
	# Verificar teclas
	beq $t5, 0x77, attack_up      # 'w' = mover arriba
	beq $t5, 0x61, attack_left    # 'a' = mover izquierda
	beq $t5, 0x73, attack_down    # 's' = mover abajo
	beq $t5, 0x64, attack_right   # 'd' = mover derecha
	beq $t5, 0x65, fire           # 'e' = disparar
	beq $t5, 0x7A, exit           # 'z' = salir
	
	b attack_loop

# ============= MOVIMIENTO DEL CURSOR DE ATAQUE =============
attack_up:
	lw $s0, attack_cursor
	addi $s1, $s0, -64           # nueva posición
	
	# Para PvE, verificar límites del jugador
	lw $s2, game_mode
	beq $s2, 2, check_up_pve
	
	# PvP - verificar límites según jugador
	lw $s2, current_player
	beq $s2, 1, check_up_player1
	
check_up_player2:
	# Jugador 2 no puede subir más allá de la primera fila
	blt $s1, 0, attack_loop
	b move_attack_cursor_up
	
check_up_player1:
	# Jugador 1 no puede subir más allá de la línea roja
	blt $s1, 1088, attack_loop
	b move_attack_cursor_up
	
check_up_pve:
	# En PvE, jugador ataca tablero inferior, no puede subir más allá de línea roja
	blt $s1, 1088, attack_loop
	
move_attack_cursor_up:
	jal clear_attack_cursor
	sw $s1, attack_cursor
	jal paint_attack_cursor
	b attack_loop

attack_left:
	lw $s0, attack_cursor
	
	# Verificar que no esté en el borde izquierdo
	andi $s1, $s0, 63
	beq $s1, 0, attack_loop
	
	addi $s1, $s0, -4
	jal clear_attack_cursor
	sw $s1, attack_cursor
	jal paint_attack_cursor
	b attack_loop

attack_right:
	lw $s0, attack_cursor
	
	# Verificar que no esté en el borde derecho
	andi $s1, $s0, 63
	li $s2, 60
	beq $s1, $s2, attack_loop
	
	addi $s1, $s0, 4
	jal clear_attack_cursor
	sw $s1, attack_cursor
	jal paint_attack_cursor
	b attack_loop

attack_down:
	lw $s0, attack_cursor
	addi $s1, $s0, 64
	
	# Para PvE, verificar límites
	lw $s2, game_mode
	beq $s2, 2, check_down_pve
	
	# PvP - verificar límites según jugador
	lw $s2, current_player
	beq $s2, 1, check_down_player1
	
check_down_player2:
	# Jugador 2 no puede bajar más allá de la línea roja
	bge $s1, 960, attack_loop
	b move_attack_cursor_down
	
check_down_player1:
	# Jugador 1 no puede bajar más allá del final
	bge $s1, 2048, attack_loop
	b move_attack_cursor_down
	
check_down_pve:
	# En PvE, jugador ataca tablero inferior, no puede salirse del tablero
	bge $s1, 2048, attack_loop
	
move_attack_cursor_down:
	jal clear_attack_cursor
	sw $s1, attack_cursor
	jal paint_attack_cursor
	b attack_loop

# ============= FUNCIÓN DE DISPARO CON COMODÍN DE ÁREA (CORREGIDA) =============
fire:
	# PRIMERO: Verificar si ya se atacó esta posición (ANTES del número aleatorio)
	lw $s1, saved_pixel_color
	
	# Verificar si ya se disparó aquí
	lw $s2, white
	beq $s1, $s2, attack_loop    # Ya es blanco (fallo previo) - SALIR SIN ATACAR
	lw $s3, red
	beq $s1, $s3, attack_loop    # Ya es rojo (impacto previo) - SALIR SIN ATACAR
	
	# SOLO SI NO HA SIDO ATACADO: Generar número aleatorio para comodín
	li $v0, 42           # syscall para random int range
	li $a0, 0            # generator ID
	li $a1, 7            # rango 0-6 (7 posibilidades)
	syscall              # resultado en $a0
	
	# Si sale 6 (1 en 7 probabilidades), activar ataque en área
	beq $a0, 6, activate_area_attack
	
	# DISPARO NORMAL
normal_attack:
	# DETECTAR QUÉ BARCO FUE GOLPEADO usando mapa interno
	lw $s0, attack_cursor
	
	# Para PvE, siempre se ataca el mapa del jugador 2 (IA)
	lw $s3, game_mode
	beq $s3, 2, check_ai_ship_normal
	
	# PvP - verificar según jugador
	lw $s3, current_player
	beq $s3, 1, check_player2_ship_normal
	
check_player1_ship_normal:
	# Jugador 2 ataca, verificar mapa del jugador 1
	lw $s4, player1_ship_map($s0)    # $s4 = ID del barco (0=agua, 1-4=barcos)
	b check_ship_result_normal
	
check_player2_ship_normal:
	# Jugador 1 ataca, verificar mapa del jugador 2
	lw $s4, player2_ship_map($s0)    # $s4 = ID del barco (0=agua, 1-4=barcos)
	b check_ship_result_normal
	
check_ai_ship_normal:
	# En PvE, jugador ataca IA (mapa jugador 2)
	lw $s4, player2_ship_map($s0)    # $s4 = ID del barco (0=agua, 1-4=barcos)
	
check_ship_result_normal:
	# Si $s4 > 0, hay un barco (IDs van de 1-4)
	bgtz $s4, hit_detected_with_id   # Si hay barco (ID > 0), es impacto
	b miss_detected              # Si no, es fallo

# ============= COMODÍN: ATAQUE EN ÁREA 3x3 =============
# Comodín especial que se activa con 1/7 de probabilidad
# Ataca un patrón 3x3 centrado en la posición del cursor
activate_area_attack:
	# Mostrar mensaje especial
	li $v0, 4
	la $a0, area_attack_msg
	syscall
	
	# Atacar patrón 3x3 centrado en el cursor
	# Patrón: [-64-4] [-64] [-64+4]
	#         [  -4 ] [ 0 ] [ +4  ]  ← 0 = cursor actual
	#         [+64-4] [+64] [+64+4]
	
	lw $s0, attack_cursor        # posición central
	li $s1, 0                    # contador de impactos en el área
	
	# Atacar las 9 posiciones del área
	addi $sp, $sp, -8
	sw $ra, 0($sp)               # guardar dirección de retorno
	sw $s1, 4($sp)               # guardar contador de impactos
	
	# Posición 1: arriba-izquierda [-64-4]
	addi $a0, $s0, -68
	jal attack_single_position
	lw $s1, 4($sp)               # cargar contador
	add $s1, $s1, $v0            # sumar resultado (1=impacto, 0=fallo)
	sw $s1, 4($sp)               # guardar contador actualizado
	
	# Posición 2: arriba-centro [-64]
	addi $a0, $s0, -64
	jal attack_single_position
	lw $s1, 4($sp)
	add $s1, $s1, $v0
	sw $s1, 4($sp)
	
	# Posición 3: arriba-derecha [-64+4]
	addi $a0, $s0, -60
	jal attack_single_position
	lw $s1, 4($sp)
	add $s1, $s1, $v0
	sw $s1, 4($sp)
	
	# Posición 4: centro-izquierda [-4]
	addi $a0, $s0, -4
	jal attack_single_position
	lw $s1, 4($sp)
	add $s1, $s1, $v0
	sw $s1, 4($sp)
	
	# Posición 5: centro [0] - cursor actual
	move $a0, $s0
	jal attack_single_position
	lw $s1, 4($sp)
	add $s1, $s1, $v0
	sw $s1, 4($sp)
	
	# Posición 6: centro-derecha [+4]
	addi $a0, $s0, 4
	jal attack_single_position
	lw $s1, 4($sp)
	add $s1, $s1, $v0
	sw $s1, 4($sp)
	
	# Posición 7: abajo-izquierda [+64-4]
	addi $a0, $s0, 60
	jal attack_single_position
	lw $s1, 4($sp)
	add $s1, $s1, $v0
	sw $s1, 4($sp)
	
	# Posición 8: abajo-centro [+64]
	addi $a0, $s0, 64
	jal attack_single_position
	lw $s1, 4($sp)
	add $s1, $s1, $v0
	sw $s1, 4($sp)
	
	# Posición 9: abajo-derecha [+64+4]
	addi $a0, $s0, 68
	jal attack_single_position
	lw $s1, 4($sp)
	add $s1, $s1, $v0
	sw $s1, 4($sp)
	
	# Verificar si hubo impactos en el área
	lw $s1, 4($sp)               # cargar contador total de impactos
	lw $ra, 0($sp)               # restaurar dirección de retorno
	addi $sp, $sp, 8
	
	# Verificar victoria después del área
	jal check_victory_by_score
	beq $v0, 1, game_won
	
	# Si hubo AL MENOS UN impacto, continuar turno
	bgtz $s1, attack_loop        # si contador > 0, continuar atacando
	
	# Si NO hubo impactos, actuar como fallo
	lw $s3, game_mode
	beq $s3, 2, area_pve_continue    # Si es PvE, continuar sin límites
	
	# PvP - decrementar intentos solo si NO hubo impactos
	lw $s3, attempts_left
	addi $s3, $s3, -1
	sw $s3, attempts_left
	
	# Mostrar intentos restantes
	li $v0, 4
	la $a0, attempts_msg
	syscall
	
	li $v0, 1
	move $a0, $s3
	syscall
	
	li $v0, 4
	la $a0, jump
	syscall
	
	# Si quedan intentos, continuar
	bgtz $s3, attack_loop
	
	# Si no quedan intentos, cambiar turno
	b change_turn

area_pve_continue:
	# En PvE, verificar victoria y luego turno de la IA
	jal check_victory_by_score
	beq $v0, 1, game_won
	
	# Si no hubo impactos en el área, turno de la IA
	beqz $s1, ai_turn_after_area    # si contador de impactos = 0
	b attack_loop                   # si hubo impactos, jugador continúa
	
ai_turn_after_area:
	jal ai_make_attack
	
	# Verificar si la IA ganó
	jal check_ai_victory
	beq $v0, 1, ai_wins
	
	b attack_loop

# ============= FUNCIÓN PARA ATACAR UNA POSICIÓN ESPECÍFICA =============
attack_single_position:
	# $a0 = posición a atacar
	# RETORNA: $v0 = 1 si impacto, 0 si fallo/inválido
	
	# Guardar registros
	addi $sp, $sp, -16
	sw $s0, 0($sp)
	sw $s1, 4($sp)
	sw $s2, 8($sp)
	sw $ra, 12($sp)
	
	move $s0, $a0            # $s0 = posición a atacar
	
	# Verificar límites según el modo de juego
	lw $s1, game_mode
	beq $s1, 2, check_limits_pve_attacks
	
	# PvP - verificar límites según jugador que ataca
	lw $s1, current_player
	beq $s1, 1, check_limits_player1_attacks
	
check_limits_player2_attacks:
	# Jugador 2 ataca tablero superior (0 a 959)
	blt $s0, 0, attack_position_skip     # no puede ser negativo
	bge $s0, 960, attack_position_skip   # no puede llegar a línea roja
	b check_previous_attack
	
check_limits_player1_attacks:
	# Jugador 1 ataca tablero inferior (1088 a 2047)
	blt $s0, 1088, attack_position_skip  # debe estar después de línea roja
	bge $s0, 2048, attack_position_skip  # no puede salirse del tablero
	b check_previous_attack
	
check_limits_pve_attacks:
	# En PvE, jugador ataca tablero inferior (1088 a 2047)
	blt $s0, 1088, attack_position_skip  # debe estar después de línea roja
	bge $s0, 2048, attack_position_skip  # no puede salirse del tablero
	
check_previous_attack:
	# Verificar si ya se atacó esta posición
	lw $s1, display($s0)
	lw $s2, white
	beq $s1, $s2, attack_position_skip   # ya es blanco (fallo previo)
	lw $s2, red
	beq $s1, $s2, attack_position_skip   # ya es rojo (impacto previo)
	
	# Verificar si hay barco en el mapa interno
	lw $s1, game_mode
	beq $s1, 2, check_area_ai_ship
	
	# PvP - verificar según jugador
	lw $s1, current_player
	beq $s1, 1, check_area_player2_ship
	
check_area_player1_ship:
	# Jugador 2 ataca, verificar mapa del jugador 1
	lw $s2, player1_ship_map($s0)       # $s2 = ID del barco
	b process_area_attack
	
check_area_player2_ship:
	# Jugador 1 ataca, verificar mapa del jugador 2
	lw $s2, player2_ship_map($s0)       # $s2 = ID del barco
	b process_area_attack
	
check_area_ai_ship:
	# En PvE, jugador ataca IA (mapa jugador 2)
	lw $s2, player2_ship_map($s0)       # $s2 = ID del barco
	
process_area_attack:
	# Si $s2 > 0, hay un barco
	bgtz $s2, area_hit_detected
	
	# FALLO en esta posición del área
area_miss_detected:
	lw $s1, white
	sw $s1, display($s0)             # pintar blanco
	li $v0, 0                        # retornar 0 (fallo)
	b attack_position_done
	
	# IMPACTO en esta posición del área
area_hit_detected:
	# Pintar de rojo
	lw $s1, red
	sw $s1, display($s0)
	
	# Incrementar puntuación (1 punto por hit) - siempre jugador 1 en PvE
	lw $s1, game_mode
	beq $s1, 2, area_update_pve_score
	
	# PvP - actualizar según jugador
	lw $s1, current_player
	beq $s1, 1, area_update_player1_score
	
area_update_player2_score:
	lw $s1, player2_score
	addi $s1, $s1, 1
	# Cap score at 34
	li $t0, 34
	ble $s1, $t0, area_p2_score_ok
	move $s1, $t0
area_p2_score_ok:
	sw $s1, player2_score
	b area_check_ship_sunk
	
area_update_player1_score:
	lw $s1, player1_score
	addi $s1, $s1, 1
	# Cap score at 34
	li $t0, 34
	ble $s1, $t0, area_p1_score_ok
	move $s1, $t0
area_p1_score_ok:
	sw $s1, player1_score
	b area_check_ship_sunk
	
area_update_pve_score:
	# En PvE, siempre actualizar score del jugador 1
	lw $s1, player1_score
	addi $s1, $s1, 1
	# Cap score at 34
	li $t0, 34
	ble $s1, $t0, area_pve_score_ok
	move $s1, $t0
area_pve_score_ok:
	sw $s1, player1_score
	
area_check_ship_sunk:
	# Decrementar salud del barco específico
	addi $s1, $s2, -1        # convertir ID a índice (1->0, 2->1, etc.)
	sll $s1, $s1, 2          # multiplicar por 4 para offset
	
	# Obtener array de salud según modo y jugador atacado
	lw $t8, game_mode
	beq $t8, 2, area_decrease_ai_health
	
	# PvP - obtener según jugador atacado
	lw $t8, current_player
	beq $t8, 1, area_decrease_player2_health
	
area_decrease_player1_health:
	lw $t9, player1_ships_health($s1)   # cargar salud actual
	addi $t9, $t9, -1                   # decrementar salud
	sw $t9, player1_ships_health($s1)   # guardar nueva salud
	b area_check_if_sunk
	
area_decrease_player2_health:
	lw $t9, player2_ships_health($s1)   # cargar salud actual
	addi $t9, $t9, -1                   # decrementar salud
	sw $t9, player2_ships_health($s1)   # guardar nueva salud
	b area_check_if_sunk
	
area_decrease_ai_health:
	# En PvE, siempre decrementar salud de la IA (jugador 2)
	lw $t9, player2_ships_health($s1)   # cargar salud actual
	addi $t9, $t9, -1                   # decrementar salud
	sw $t9, player2_ships_health($s1)   # guardar nueva salud
	
area_check_if_sunk:
	# Si salud = 0, el barco se hundió (dar bonus de 5 puntos)
	bne $t9, 0, area_hit_success
	
	# BARCO HUNDIDO en ataque de área - dar bonus
	li $v0, 4
	la $a0, ship_sunk_msg
	syscall
	
	# Dar 5 puntos extra según modo de juego
	lw $t8, game_mode
	beq $t8, 2, area_bonus_pve
	
	# PvP - dar bonus según jugador
	lw $t8, current_player
	beq $t8, 1, area_bonus_player1
	
area_bonus_player2:
	lw $t8, player2_score
	addi $t8, $t8, 5
	# Cap score at 34
	li $t0, 34
	ble $t8, $t0, area_bonus_p2_ok
	move $t8, $t0
area_bonus_p2_ok:
	sw $t8, player2_score
	b area_hit_success
	
area_bonus_player1:
	lw $t8, player1_score
	addi $t8, $t8, 5
	# Cap score at 34
	li $t0, 34
	ble $t8, $t0, area_bonus_p1_ok
	move $t8, $t0
area_bonus_p1_ok:
	sw $t8, player1_score
	b area_hit_success
	
area_bonus_pve:
	# En PvE, siempre dar bonus al jugador 1
	lw $t8, player1_score
	addi $t8, $t8, 5
	# Cap score at 34
	li $t0, 34
	ble $t8, $t0, area_bonus_pve_ok
	move $t8, $t0
area_bonus_pve_ok:
	sw $t8, player1_score

area_hit_success:
	li $v0, 1                        # retornar 1 (impacto)
	b attack_position_done

attack_position_skip:
	# Posición fuera de límites o ya atacada
	li $v0, 0                        # retornar 0 (fallo/inválido)
	
attack_position_done:
	# Restaurar registros
	lw $s0, 0($sp)
	lw $s1, 4($sp)
	lw $s2, 8($sp)
	lw $ra, 12($sp)
	addi $sp, $sp, 16
	jr $ra

# ============= FUNCIÓN DE FALLO (DISPARO NORMAL) =============
miss_detected:
	# Actualizar el color guardado a blanco
	lw $s2, white
	sw $s2, saved_pixel_color
	
	# Pintar de blanco en el display
	lw $s0, attack_cursor
	sw $s2, display($s0)
	
	# Mostrar mensaje de fallo
	li $v0, 4
	la $a0, miss_msg
	syscall
	
	# Verificar modo de juego
	lw $s3, game_mode
	beq $s3, 2, pve_miss_continue   # En PvE, continuar sin límites
	
	# PvP - decrementar intentos
	lw $s3, attempts_left
	addi $s3, $s3, -1
	sw $s3, attempts_left
	
	# Mostrar intentos restantes
	li $v0, 4
	la $a0, attempts_msg
	syscall
	
	li $v0, 1
	move $a0, $s3
	syscall
	
	li $v0, 4
	la $a0, jump
	syscall
	
	# Si quedan intentos, continuar
	bgtz $s3, attack_loop
	
	# Si no quedan intentos, cambiar turno
	b change_turn

pve_miss_continue:
	# En PvE, después del fallo del jugador, turno de la IA
	jal ai_make_attack
	
	# Verificar si la IA ganó
	jal check_ai_victory
	beq $v0, 1, ai_wins
	
	b attack_loop

# ============= FUNCIÓN DE IMPACTO (DISPARO NORMAL) =============
hit_detected_with_id:
	# $s4 contiene el ID del barco golpeado (1-4)
	
	# Actualizar el color guardado a rojo
	lw $s1, red
	sw $s1, saved_pixel_color
	
	# Pintar de rojo en el display
	lw $s0, attack_cursor
	sw $s1, display($s0)
	
	# Mostrar mensaje de impacto
	li $v0, 4
	la $a0, hit_msg
	syscall
	
	# INCREMENTAR PUNTUACIÓN (1 punto por hit)
	lw $s3, game_mode
	beq $s3, 2, update_pve_score_hit
	
	# PvP - actualizar según jugador
	lw $s3, current_player
	beq $s3, 1, update_player1_score_hit
	
update_player2_score_hit:
	lw $s3, player2_score
	addi $s3, $s3, 1         # +1 punto por impacto
	# Cap score at 34
	li $t0, 34
	ble $s3, $t0, hit_p2_score_ok
	move $s3, $t0
hit_p2_score_ok:
	sw $s3, player2_score
	b check_ship_sunk_new
	
update_player1_score_hit:
	lw $s3, player1_score
	addi $s3, $s3, 1         # +1 punto por impacto
	# Cap score at 34
	li $t0, 34
	ble $s3, $t0, hit_p1_score_ok
	move $s3, $t0
hit_p1_score_ok:
	sw $s3, player1_score
	b check_ship_sunk_new
	
update_pve_score_hit:
	# En PvE, siempre actualizar jugador 1
	lw $s3, player1_score
	addi $s3, $s3, 1         # +1 punto por impacto
	# Cap score at 34
	li $t0, 34
	ble $s3, $t0, hit_pve_score_ok
	move $s3, $t0
hit_pve_score_ok:
	sw $s3, player1_score
	
check_ship_sunk_new:
	# DECREMENTAR SALUD DEL BARCO ESPECÍFICO
	# $s4 = ID del barco (1-4), necesitamos índice array (0-3)
	addi $s5, $s4, -1        # convertir ID a índice (1->0, 2->1, etc.)
	sll $s5, $s5, 2          # multiplicar por 4 para offset del array
	
	# Obtener array de salud según modo y jugador atacado
	lw $s3, game_mode
	beq $s3, 2, decrease_ai_health
	
	# PvP - obtener según jugador atacado
	lw $s3, current_player
	beq $s3, 1, decrease_player2_health
	
decrease_player1_health:
	# Jugador 2 ataca al jugador 1
	lw $s6, player1_ships_health($s5)    # cargar salud actual del barco
	addi $s6, $s6, -1                    # decrementar salud
	sw $s6, player1_ships_health($s5)    # guardar nueva salud
	b check_if_sunk
	
decrease_player2_health:
	# Jugador 1 ataca al jugador 2
	lw $s6, player2_ships_health($s5)    # cargar salud actual del barco
	addi $s6, $s6, -1                    # decrementar salud
	sw $s6, player2_ships_health($s5)    # guardar nueva salud
	b check_if_sunk
	
decrease_ai_health:
	# En PvE, jugador ataca a la IA (jugador 2)
	lw $s6, player2_ships_health($s5)    # cargar salud actual del barco
	addi $s6, $s6, -1                    # decrementar salud
	sw $s6, player2_ships_health($s5)    # guardar nueva salud
	
check_if_sunk:
	# Si salud = 0, el barco se hundió
	beq $s6, 0, ship_sunk
	
	# El barco aún no se hunde, verificar victoria general
	jal check_victory_by_score
	beq $v0, 1, game_won
	
	# En PvE, después de impacto (sin hundir), jugador continúa
	lw $s3, game_mode
	beq $s3, 2, attack_loop     # En PvE, jugador continúa después de impacto
	
	# Continuar ataque (turno repite)
	b attack_loop

# BARCO HUNDIDO - DAR PUNTOS EXTRA Y MOSTRAR MENSAJE
ship_sunk:
	# Mostrar mensaje "¡HUNDIDO!"
	li $v0, 4
	la $a0, ship_sunk_msg
	syscall
	
	# DAR 5 PUNTOS EXTRA por hundir barco
	lw $s3, game_mode
	beq $s3, 2, bonus_pve
	
	# PvP - dar bonus según jugador
	lw $s3, current_player
	beq $s3, 1, bonus_player1
	
bonus_player2:
	lw $s3, player2_score
	addi $s3, $s3, 5         # +5 puntos extra por hundir
	# Cap score at 34
	li $t0, 34
	ble $s3, $t0, bonus_p2_score_ok
	move $s3, $t0
bonus_p2_score_ok:
	sw $s3, player2_score
	b check_victory_after_sink
	
bonus_player1:
	lw $s3, player1_score
	addi $s3, $s3, 5         # +5 puntos extra por hundir
	# Cap score at 34
	li $t0, 34
	ble $s3, $t0, bonus_p1_score_ok
	move $s3, $t0
bonus_p1_score_ok:
	sw $s3, player1_score
	b check_victory_after_sink
	
bonus_pve:
	# En PvE, siempre dar bonus al jugador 1
	lw $s3, player1_score
	addi $s3, $s3, 5         # +5 puntos extra por hundir
	# Cap score at 34
	li $t0, 34
	ble $s3, $t0, bonus_pve_score_ok
	move $s3, $t0
bonus_pve_score_ok:
	sw $s3, player1_score
	
check_victory_after_sink:
	# Verificar victoria (34 puntos = todos los barcos hundidos)
	jal check_victory_by_score
	beq $v0, 1, game_won
	
	# En PvE, después de hundir barco, jugador continúa (no turno IA)
	lw $s3, game_mode
	beq $s3, 2, attack_loop     # En PvE, jugador continúa después de hundir
	
	# Continuar ataque (turno repite)
	b attack_loop

# ============= VERIFICAR VICTORIA POR PUNTUACIÓN =============
check_victory_by_score:
	# Verificar si el jugador actual alcanzó 34 puntos (victoria total)
	# 14 puntos por hits + 20 puntos por hundimientos = 34 puntos máximo
	
	lw $s0, game_mode
	beq $s0, 2, check_pve_victory
	
	# PvP - verificar según jugador actual
	lw $s0, current_player
	beq $s0, 1, check_player1_score
	
check_player2_score:
	lw $s1, player2_score
	b compare_score
	
check_player1_score:
	lw $s1, player1_score
	b compare_score
	
check_pve_victory:
	# En PvE, solo verificar jugador 1
	lw $s1, player1_score
	
compare_score:
	# Si score >= 34, victoria completa
	li $s2, 34
	bge $s1, $s2, victory_achieved
	
	# Aún no hay victoria
	li $v0, 0
	jr $ra
	
victory_achieved:
	# Victoria alcanzada
	li $v0, 1
	jr $ra

change_turn:
	# Cambiar de jugador
	lw $s0, current_player
	li $s1, 3
	sub $s0, $s1, $s0        # 3 - current_player
	sw $s0, current_player
	
	# FORZAR REPINTADO DE LÍNEAS SEPARADORAS EN MORADO
	jal repaint_separator_lines
	
	# NUEVO: Mostrar barcos propios del nuevo jugador
	beq $s0, 1, show_own_ships_p1
	
show_own_ships_p2:
	jal show_player2_ships
	b reset_attempts
	
show_own_ships_p1:
    # Mostrar barcos propios del jugador 1 cuando cambia a su turno
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    jal show_player1_ships
    lw $ra, 0($sp)
    addi $sp, $sp, 4
	
reset_attempts:
	# Resetear intentos
	li $s1, 3
	sw $s1, attempts_left
	
	b show_attack_turn

# ============= JUEGO GANADO =============
game_won:
	# Mostrar quién ganó según modo de juego
	lw $s0, game_mode
	beq $s0, 2, pve_victory
	
	# PvP - mostrar ganador según jugador actual
	lw $s0, current_player
	beq $s0, 1, player1_wins
	
player2_wins:
	li $v0, 4
	la $a0, player2_wins_msg
	syscall
	b show_final_score
	
player1_wins:
	li $v0, 4
	la $a0, player1_wins_msg
	syscall
	b show_final_score
	
pve_victory:
	# En PvE, siempre gana el jugador 1
	li $v0, 4
	la $a0, player1_wins_msg
	syscall
	
show_final_score:
	# Mostrar título de puntuaciones finales
	li $v0, 4
	la $a0, final_scores_title
	syscall
	
	# Jugador 1
	li $v0, 4
	la $a0, player1_score_msg
	syscall
	
	li $v0, 1
	lw $a0, player1_score
	syscall
	
	li $v0, 4
	la $a0, jump
	syscall
	
	# En PvE, no mostrar score del jugador 2 (IA)
	lw $s0, game_mode
	beq $s0, 2, show_cpu_score
	
	# Jugador 2 (solo en PvP)
	li $v0, 4
	la $a0, player2_score_msg
	syscall
	
	li $v0, 1
	lw $a0, player2_score
	syscall
	
	li $v0, 4
	la $a0, jump
	syscall
	b end_final_score
	
show_cpu_score:
	# Mostrar puntuación de la CPU en PvE
	li $v0, 4
	la $a0, cpu_score_msg
	syscall
	
	li $v0, 1
	lw $a0, player2_score      # La IA usa player2_score internamente
	syscall
	
	li $v0, 4
	la $a0, jump
	syscall
	
end_final_score:
	li $v0, 4
	la $a0, game_over_msg
	syscall
	
	b exit

# ============= FUNCIONES DE CURSOR DE ATAQUE =============
clear_attack_cursor:
	# Guardar registros
	addi $sp, $sp, -8
	sw $s0, 0($sp)
	sw $s1, 4($sp)
	
	lw $s0, attack_cursor
	lw $s1, display($s0)
	
	# Si es verde (cursor), restaurar el color guardado
	lw $s2, green
	bne $s1, $s2, clear_cursor_done
	
	# Restaurar el color original guardado
	lw $s1, saved_pixel_color
	sw $s1, display($s0)
	
clear_cursor_done:
	lw $s0, 0($sp)
	lw $s1, 4($sp)
	addi $sp, $sp, 8
	jr $ra

paint_attack_cursor:
	# Guardar registros
	addi $sp, $sp, -8
	sw $s0, 0($sp)
	sw $s1, 4($sp)
	
	lw $s0, attack_cursor
	
	# IMPORTANTE: Guardar el color del nuevo pixel ANTES de pintarlo verde
	lw $s1, display($s0)
	sw $s1, saved_pixel_color
	
	# Pintar verde
	lw $s1, green
	sw $s1, display($s0)
	
	lw $s0, 0($sp)
	lw $s1, 4($sp)
	addi $sp, $sp, 8
	jr $ra

# =================== FUNCIONES DE PINTADO Y VISUALIZACIÓN ===================

# Pintar el barco actual en color amarillo (preview/modo colocación)
paint_current_ship:
	# Guardar registros en stack
	addi $sp, $sp, -32
	sw $t8, 0($sp)           # índice barco
	sw $t9, 4($sp)           # tamaño barco  
	sw $s6, 8($sp)           # contador
	sw $s7, 12($sp)          # posición
	sw $s4, 16($sp)          # orientación
	sw $s5, 20($sp)          # temp
	sw $ra, 24($sp)          # dirección de retorno
	sw $a0, 28($sp)          # guardar $a0 también
	
	# Obtener información del barco actual
	lw $t8, current_ship     # índice del barco (0, 1, 2, o 3)
	sll $t9, $t8, 2          # multiplicar por 4 para indexar array
	lw $t9, ship_sizes($t9)  # obtener tamaño del barco
	
	move $s7, $t4            # posición inicial = posición del cursor
	lw $s4, orientation      # cargar orientación actual
	move $s6, $t9            # contador = tamaño del barco
	
paint_ship_loop:
	beq $s6, 0, paint_ship_done   # si contador = 0, terminar
	sw $t3, display($s7)     # pintar pixel amarillo en posición actual
	
	addi $s6, $s6, -1        # decrementar contador
	beq $s6, 0, paint_ship_done   # si ya terminamos, salir
	
	# Calcular siguiente posición según orientación
	beq $s4, 0, paint_horizontal  # si orientación = 0, mover horizontal
	addi $s7, $s7, 64        # vertical: mover una fila abajo
	b paint_ship_loop
	
paint_horizontal:
	addi $s7, $s7, 4         # horizontal: mover un pixel a la derecha
	b paint_ship_loop
	
paint_ship_done:
	# Restaurar registros del stack
	lw $t8, 0($sp)
	lw $t9, 4($sp)
	lw $s6, 8($sp)
	lw $s7, 12($sp)
	lw $s4, 16($sp)
	lw $s5, 20($sp)
	lw $ra, 24($sp)
	lw $a0, 28($sp)
	addi $sp, $sp, 32
	jr $ra                   # retornar

# Borrar el barco actual (restaurar a azul, PERO NO tocar barcos grises ya colocados)
clear_current_ship:
	# Guardar registros
	addi $sp, $sp, -32
	sw $t8, 0($sp)
	sw $t9, 4($sp)
	sw $s6, 8($sp)
	sw $s7, 12($sp)
	sw $s4, 16($sp)
	sw $s5, 20($sp)
	sw $ra, 24($sp)
	sw $a0, 28($sp)
	
	# Obtener información del barco actual
	lw $t8, current_ship
	sll $t9, $t8, 2
	lw $t9, ship_sizes($t9)  # tamaño del barco
	
	move $s7, $t4            # posición inicial
	lw $s4, orientation      # orientación
	move $s6, $t9            # contador
	
clear_ship_loop:
	beq $s6, 0, clear_ship_done
	
	# VERIFICAR que no sea un barco gris antes de pintar azul
	lw $s5, display($s7)     # leer color actual
	beq $s5, $t7, clear_skip # si es gris (barco colocado), NO tocar
	
	sw $t0, display($s7)     # usar $t0 (azul) directamente
	
clear_skip:
	addi $s6, $s6, -1
	beq $s6, 0, clear_ship_done
	
	# Mover a siguiente posición (mismo algoritmo que paint)
	beq $s4, 0, clear_horizontal
	addi $s7, $s7, 64        # vertical
	b clear_ship_loop
	
clear_horizontal:
	addi $s7, $s7, 4         # horizontal
	b clear_ship_loop
	
clear_ship_done:
	# Restaurar registros
	lw $t8, 0($sp)
	lw $t9, 4($sp)
	lw $s6, 8($sp)
	lw $s7, 12($sp)
	lw $s4, 16($sp)
	lw $s5, 20($sp)
	lw $ra, 24($sp)
	lw $a0, 28($sp)
	addi $sp, $sp, 32
	jr $ra

# Colocar el barco permanentemente (cambiar a gris y guardar en mapa interno con ID)
place_current_ship:
	# Guardar registros
	addi $sp, $sp, -32
	sw $t8, 0($sp)           # índice barco
	sw $t9, 4($sp)           # tamaño barco
	sw $s6, 8($sp)           # contador de píxeles
	sw $s7, 12($sp)          # posición actual  
	sw $s4, 16($sp)          # orientación
	sw $s5, 20($sp)          # temp
	sw $ra, 24($sp)
	sw $a0, 28($sp)
	
	# Obtener información del barco actual
	lw $t8, current_ship     # índice del barco (0, 1, 2, 3)
	sll $t9, $t8, 2          # multiplicar por 4 para indexar array
	lw $t9, ship_sizes($t9)  # tamaño del barco
	
	move $s7, $t4            # posición inicial
	lw $s4, orientation      # orientación
	move $s6, $t9            # contador
	
	# CALCULAR ID DEL BARCO: current_ship + 1 (1=portaaviones, 2=acorazado, etc.)
	addi $s5, $t8, 1         # ID del barco (1-4)
	
place_ship_loop:
	beq $s6, 0, place_ship_done   # si contador = 0, terminar
	
	# Pintar pixel GRIS (visual)
	sw $t7, display($s7)
	
	# Guardar ID del barco en el mapa correspondiente (para detección de impactos)
	lw $t8, current_player
	beq $t8, 1, save_player1_map
	
save_player2_map:
	# Guardar ID del barco en mapa del jugador 2
	sw $s5, player2_ship_map($s7)   # $s5 = ID del barco (1-4)
	b continue_place_loop
	
save_player1_map:
	# Guardar ID del barco en mapa del jugador 1
	sw $s5, player1_ship_map($s7)   # $s5 = ID del barco (1-4)
	
continue_place_loop:
	addi $s6, $s6, -1        # decrementar contador
	beq $s6, 0, place_ship_done   # si ya terminamos, salir
	
	# Mover a siguiente posición
	beq $s4, 0, place_horizontal
	addi $s7, $s7, 64        # vertical
	b place_ship_loop
	
place_horizontal:
	addi $s7, $s7, 4         # horizontal
	b place_ship_loop
	
place_ship_done:
	# Restaurar registros
	lw $t8, 0($sp)
	lw $t9, 4($sp)
	lw $s6, 8($sp)
	lw $s7, 12($sp)
	lw $s4, 16($sp)
	lw $s5, 20($sp)
	lw $ra, 24($sp)
	lw $a0, 28($sp)
	addi $sp, $sp, 32
	jr $ra

# =================== SUBRUTINAS DE VALIDACIÓN ===================

# Verificar si se puede mover hacia arriba
can_move_up:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	addi $t8, $t4, -64       # calcular nueva posición (una fila arriba)
	jal check_position_valid # verificar si esa posición es válida
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra                   # retornar con resultado en $v0

# Verificar si se puede mover hacia la izquierda
can_move_left:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	addi $t8, $t4, -4        # calcular nueva posición (un pixel a la izquierda)
	jal check_position_valid
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

# Verificar si se puede mover hacia la derecha
can_move_right:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	addi $t8, $t4, 4         # calcular nueva posición (un pixel a la derecha)
	jal check_position_valid
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

# Verificar si se puede mover hacia abajo
can_move_down:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	addi $t8, $t4, 64        # calcular nueva posición (una fila abajo)
	jal check_position_valid
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

# Verificar si la posición actual es válida (para rotación)
is_valid_position:
	move $t8, $t4            # usar posición actual del cursor
	# continúa ejecutando check_position_valid

# Verificar si una posición específica es válida para el barco completo
check_position_valid:
	# $t8 contiene la posición a verificar
	addi $sp, $sp, -12
	sw $s1, 0($sp)           # contador
	sw $s2, 4($sp)           # posición siendo verificada
	sw $s3, 8($sp)           # orientación
	
	# Obtener información del barco actual
	lw $s1, current_ship
	sll $s2, $s1, 2
	lw $s1, ship_sizes($s2)  # tamaño del barco en $s1
	
	move $s2, $t8            # posición inicial a verificar
	lw $s3, orientation      # orientación actual
	
	# *** NUEVA VERIFICACIÓN: posición inicial no debe ser gris ***
	lw $t9, display($s2)
	beq $t9, $t7, check_invalid     # si cursor está sobre barco gris, inválido
	
check_loop:
	beq $s1, 0, check_valid  # si verificamos todos los píxeles, es válido
	
	# Verificar límites del tablero según el jugador
	lw $t9, current_player
	beq $t9, 1, check_player1_bounds
	
check_player2_bounds:
	# Jugador 2: debe estar después de línea roja
	blt $s2, 1088, check_invalid    # debe estar después de línea roja
	bge $s2, 2048, check_invalid    # no puede salirse del tablero
	b check_edges
	
check_player1_bounds:
	# Jugador 1: debe estar antes de línea roja
	blt $s2, 0, check_invalid       # no puede ser negativo
	bge $s2, 960, check_invalid     # no puede pasar la línea roja (fila 15)
	
check_edges:
	# Verificar bordes según orientación
	beq $s3, 1, check_collision
	
	# Para orientación horizontal: verificar borde derecho
	andi $t9, $s2, 63        # $s2 % 64 (posición dentro de la fila)
	addi $t9, $t9, 4         # siguiente posición
	beq $t9, 64, check_edge  # si llegaría al borde, verificar especialmente
	b check_collision
	
check_edge:
	beq $s1, 1, check_collision  # si es el último pixel del barco, ok
	b check_invalid              # si no, se saldría del borde

check_collision:
	# Verificar colisiones con barcos existentes
	lw $t9, display($s2)
	beq $t9, $t7, check_invalid     # si hay barco gris (colocado), colisión
	lw $t8, purple
	beq $t9, $t8, check_invalid     # si es línea morada, inválido
	
	# Mover a siguiente posición del barco
	beq $s3, 0, check_horizontal
	addi $s2, $s2, 64        # vertical: siguiente fila
	b check_continue
	
check_horizontal:
	addi $s2, $s2, 4         # horizontal: siguiente columna
	
check_continue:
	addi $s1, $s1, -1        # decrementar contador
	b check_loop             # verificar siguiente pixel

check_valid:
	li $v0, 1                # retornar 1 (válido)
	b check_done

check_invalid:
	li $v0, 0                # retornar 0 (inválido)

check_done:
	# Restaurar registros
	lw $s1, 0($sp)
	lw $s2, 4($sp)
	lw $s3, 8($sp)
	addi $sp, $sp, 12
	jr $ra

# ============= FUNCIONES PARA ESCONDER/MOSTRAR BARCOS =============

# Esconder barcos del jugador 1 (convertir grises a azules en tablero superior)
hide_player1_ships:
	addi $sp, $sp, -12
	sw $s0, 0($sp)
	sw $s1, 4($sp)
	sw $ra, 8($sp)
	
	li $s0, 0                # posición inicial (tablero superior)
	li $s1, 960              # posición final (antes de línea roja)
	
hide_p1_loop:
	bge $s0, $s1, hide_p1_done
	
	# Si el pixel es gris (barco), cambiarlo a azul
	lw $s2, display($s0)
	bne $s2, $t7, hide_p1_continue   # si no es gris, continuar
	
	sw $t0, display($s0)     # cambiar a azul
	
hide_p1_continue:
	addi $s0, $s0, 4
	b hide_p1_loop
	
hide_p1_done:
	lw $s0, 0($sp)
	lw $s1, 4($sp)
	lw $ra, 8($sp)
	addi $sp, $sp, 12
	jr $ra

# Esconder barcos del jugador 2 (convertir grises a azules en tablero inferior)
hide_player2_ships:
	addi $sp, $sp, -12
	sw $s0, 0($sp)
	sw $s1, 4($sp)
	sw $ra, 8($sp)
	
	li $s0, 1088             # posición inicial (después de línea roja)
	li $s1, 2048             # posición final
	
hide_p2_loop:
	bge $s0, $s1, hide_p2_done
	
	# Si el pixel es gris (barco), cambiarlo a azul
	lw $s2, display($s0)
	bne $s2, $t7, hide_p2_continue   # si no es gris, continuar
	
	sw $t0, display($s0)     # cambiar a azul
	
hide_p2_continue:
	addi $s0, $s0, 4
	b hide_p2_loop
	
hide_p2_done:
	lw $s0, 0($sp)
	lw $s1, 4($sp)
	lw $ra, 8($sp)
	addi $sp, $sp, 12
	jr $ra

# Mostrar barcos del jugador 1 (restaurar grises donde hay barcos según mapa)
show_player1_ships:
	addi $sp, $sp, -12
	sw $s0, 0($sp)
	sw $s1, 4($sp)
	sw $ra, 8($sp)
	
	li $s0, 0                # posición inicial
	li $s1, 960              # posición final
	
show_p1_loop:
	bge $s0, $s1, show_p1_done
	
	# Si hay barco en el mapa (ID > 0) y el pixel no ha sido atacado
	lw $s2, player1_ship_map($s0)
	beq $s2, 0, show_p1_continue     # si no hay barco (ID=0), continuar
	
	lw $s3, display($s0)
	lw $s4, red
	beq $s3, $s4, show_p1_continue   # si es rojo (atacado), no tocar
	lw $s4, white
	beq $s3, $s4, show_p1_continue   # si es blanco (atacado), no tocar
	
	sw $t7, display($s0)     # restaurar gris
	
show_p1_continue:
	addi $s0, $s0, 4
	b show_p1_loop
	
show_p1_done:
	lw $s0, 0($sp)
	lw $s1, 4($sp)
	lw $ra, 8($sp)
	addi $sp, $sp, 12
	jr $ra

# Mostrar barcos del jugador 2 (restaurar grises donde hay barcos según mapa)
show_player2_ships:
	addi $sp, $sp, -12
	sw $s0, 0($sp)
	sw $s1, 4($sp)
	sw $ra, 8($sp)
	
	li $s0, 1088             # posición inicial
	li $s1, 2048             # posición final
	
show_p2_loop:
	bge $s0, $s1, show_p2_done
	
	# Si hay barco en el mapa (ID > 0) y el pixel no ha sido atacado
	lw $s2, player2_ship_map($s0)
	beq $s2, 0, show_p2_continue     # si no hay barco (ID=0), continuar
	
	lw $s3, display($s0)
	lw $s4, red
	beq $s3, $s4, show_p2_continue   # si es rojo (atacado), no tocar
	lw $s4, white
	beq $s3, $s4, show_p2_continue   # si es blanco (atacado), no tocar
	
	sw $t7, display($s0)     # restaurar gris
	
show_p2_continue:
	addi $s0, $s0, 4
	b show_p2_loop
	
show_p2_done:
	lw $s0, 0($sp)
	lw $s1, 4($sp)
	lw $ra, 8($sp)
	addi $sp, $sp, 12
	jr $ra

# ============= FUNCIÓN PARA REPINTAR LÍNEAS SEPARADORAS =============
repaint_separator_lines:
	addi $sp, $sp, -12
	sw $s0, 0($sp)
	sw $s1, 4($sp)           # guardar $t2 original
	sw $ra, 8($sp)
	
	move $s1, $t2            # guardar valor original de $t2 (rojo)
	li $t2, 0x800080         # cambiar temporalmente a morado
	
	# Repintar línea separadora morada (2 filas: 15 y 16)
	li $s0, 960              # empezar en fila 15 (15 × 64 = 960)
	
repaint_row1:
	sw $t2, display($s0)     # pintar pixel morado
	addi $s0, $s0, 4         # siguiente pixel
	beq $s0, 1024, repaint_row2  # si completamos fila 15, ir a fila 16
	b repaint_row1
	
repaint_row2:
	sw $t2, display($s0)     # pintar pixel morado
	addi $s0, $s0, 4         # siguiente pixel
	beq $s0, 1088, repaint_done  # si completamos fila 16, terminar
	b repaint_row2

repaint_done:
	move $t2, $s1            # restaurar valor original de $t2 (rojo)
	lw $s0, 0($sp)
	lw $s1, 4($sp)
	lw $ra, 8($sp)
	addi $sp, $sp, 12
	jr $ra

# ============= INTELIGENCIA ARTIFICIAL (ALGORITMO HUNT & TARGET) =============

# Función principal de ataque de la IA
# Implementa el algoritmo "Hunt & Target":
# - HUNT: Ataque aleatorio hasta encontrar un barco
# - TARGET: Exploración sistemática alrededor del impacto hasta hundirlo
ai_make_attack:
	# Guardar registros
	addi $sp, $sp, -8
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	
	# Verificar modo de la IA
	lw $s0, ai_mode
	beq $s0, 0, ai_hunt_mode
	beq $s0, 1, ai_target_mode
	
ai_hunt_mode:
	# Modo hunting: ataque aleatorio hasta encontrar barco
	jal ai_hunt_random
	b ai_attack_done
	
ai_target_mode:
	# Modo targeting: ataque dirigido alrededor del impacto
	jal ai_target_ship
	b ai_attack_done
	
ai_attack_done:
	# Restaurar registros y retornar
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	addi $sp, $sp, 8
	jr $ra

# MODO HUNT: Generación de ataques aleatorios
ai_hunt_random:
	# Guardar registros
	addi $sp, $sp, -12
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	
hunt_retry:
	# Generar posición aleatoria en tablero superior (0-959)
	jal generate_random_position
	move $s0, $v0            # $s0 = posición generada
	
	# Verificar si ya fue atacada (no perder turno por posiciones inválidas)
	move $a0, $s0
	jal is_position_already_attacked
	beq $v0, 1, hunt_retry   # Si ya atacada, generar otra posición
	
	# Atacar la posición válida
	move $a0, $s0
	jal ai_attack_position
	
	# Si fue impacto, cambiar a targeting mode
	beq $v0, 1, switch_to_targeting
	
	# Si fue fallo, continuar en hunting
	b hunt_done
	
switch_to_targeting:
	# Cambiar a modo targeting
	li $s1, 1
	sw $s1, ai_mode
	
	# Guardar posición del impacto para exploración
	sw $s0, ai_target_pos
	sw $s0, ai_original_hit
	
	# Resetear dirección y pasos
	sw $zero, ai_direction
	sw $zero, ai_steps_in_direction
	
hunt_done:
	# Restaurar registros
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	addi $sp, $sp, 12
	jr $ra

# MODO TARGET: Exploración sistemática alrededor de impactos
# Esta función explora direcciones adyacentes (arriba, derecha, abajo, izquierda)
# una por turno hasta encontrar el barco completo o agotarlas todas
ai_target_ship:
	# Guardar registros
	addi $sp, $sp, -16
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	sw $s2, 12($sp)
	
	lw $s0, ai_target_pos     # posición actual objetivo
	lw $s1, ai_direction      # dirección actual (0=arriba, 1=derecha, 2=abajo, 3=izquierda)
	
	# Buscar la siguiente posición válida para atacar (un ataque por turno)
find_valid_target:
	# Verificar que aún hay direcciones por probar
	bge $s1, 4, no_more_directions
	
	# Obtener posición adyacente en dirección actual
	move $a0, $s0            # posición base
	move $a1, $s1            # dirección
	jal get_adjacent_position
	
	# Verificar límites del tablero (tablero superior para atacar jugador)
	blt $v0, 0, try_next_direction_immediately       # fuera de límites
	bge $v0, 960, try_next_direction_immediately     # fuera de tablero superior
	
	move $s2, $v0            # $s2 = posición adyacente
	
	# Verificar bordes horizontales (evitar "wrap-around" entre filas)
	beq $s1, 1, check_right_edge    # dirección derecha
	beq $s1, 3, check_left_edge     # dirección izquierda
	b check_if_attacked
	
check_right_edge:
	# Verificar que no se salga del borde derecho
	andi $t0, $s0, 63        # posición % 64 (posición en la fila)
	andi $t1, $s2, 63        # nueva posición % 64
	blt $t1, $t0, try_next_direction_immediately   # se envolvió a siguiente fila
	b check_if_attacked
	
check_left_edge:
	# Verificar que no se salga del borde izquierdo
	andi $t0, $s0, 63        # posición % 64
	andi $t1, $s2, 63        # nueva posición % 64
	bgt $t1, $t0, try_next_direction_immediately   # se envolvió a fila anterior
	
check_if_attacked:
	# Verificar si ya fue atacada (no perder turno)
	move $a0, $s2
	jal is_position_already_attacked
	beq $v0, 1, try_next_direction_immediately   # ya atacada, siguiente dirección SIN perder turno
	
	# ¡Encontramos posición válida! Atacar UNA SOLA vez y terminar turno
	move $a0, $s2
	jal ai_attack_position
	
	beq $v0, 1, target_hit_continue   # si impacto, continuar en esa dirección
	beq $v0, 2, target_ship_sunk      # si barco hundido, volver a hunting
	beq $v0, 0, target_miss_continue  # si fallo, siguiente dirección
	
target_hit_continue:
	# Impacto! Continuar en esta dirección en el SIGUIENTE turno
	sw $s2, ai_target_pos    # actualizar posición objetivo
	
	lw $s0, ai_steps_in_direction
	addi $s0, $s0, 1
	sw $s0, ai_steps_in_direction
	
	b target_done
	
target_ship_sunk:
	# Barco hundido - volver a hunting mode
	sw $zero, ai_mode
	sw $zero, ai_direction
	sw $zero, ai_steps_in_direction
	b target_done
	
target_miss_continue:
	# Fallo - cambiar dirección para el SIGUIENTE turno
	addi $s1, $s1, 1         # siguiente dirección
	sw $s1, ai_direction     # guardar nueva dirección
	
	# Resetear a posición original para nueva dirección
	lw $s0, ai_original_hit
	sw $s0, ai_target_pos
	sw $zero, ai_steps_in_direction
	
	b target_done
	
try_next_direction_immediately:
	# Posición inválida o ya atacada - probar siguiente dirección INMEDIATAMENTE (mismo turno)
	addi $s1, $s1, 1         # siguiente dirección
	
	# Resetear a posición original para nueva dirección
	lw $s0, ai_original_hit
	sw $zero, ai_steps_in_direction
	
	# Buscar siguiente posición válida SIN terminar turno
	b find_valid_target
	
no_more_directions:
	# Se acabaron las direcciones sin encontrar nada válido, volver a hunting
	sw $zero, ai_mode
	sw $zero, ai_direction
	sw $zero, ai_steps_in_direction
	
target_done:
	# Restaurar registros
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	lw $s2, 12($sp)
	addi $sp, $sp, 16
	jr $ra

# ============= FUNCIONES AUXILIARES DE LA IA =============

# Generar posición aleatoria en tablero superior (donde están los barcos del jugador)
generate_random_position:
	# Guardar registros
	addi $sp, $sp, -8
	sw $s0, 0($sp)
	sw $s1, 4($sp)
	
	li $v0, 42               # syscall para random
	li $a0, 1                # generator ID
	li $a1, 240              # rango 0-239 (240 posiciones = 15 filas × 16 columnas)
	syscall
	
	# Convertir índice lineal a posición en display
	# posición = (fila * 64) + (columna * 4)
	move $s0, $a0            # $s0 = índice lineal (0-239)
	
	# Calcular fila = índice / 16
	li $s1, 16
	div $s0, $s1
	mflo $s1                 # $s1 = fila (0-14)
	
	# Calcular columna = índice % 16  
	mfhi $s0                 # $s0 = columna (0-15)
	
	# Convertir a posición en display
	sll $s1, $s1, 6          # fila * 64
	sll $s0, $s0, 2          # columna * 4
	add $v0, $s1, $s0        # posición final
	
	# Restaurar registros
	lw $s0, 0($sp)
	lw $s1, 4($sp)
	addi $sp, $sp, 8
	jr $ra

# Verificar si posición ya fue atacada (para evitar turnos perdidos)
is_position_already_attacked:
	# Input: $a0 = posición a verificar
	# Output: $v0 = 1 si ya atacada, 0 si libre
	lw $t0, display($a0)
	lw $t1, white
	beq $t0, $t1, position_attacked    # blanco = ya atacado (fallo)
	lw $t1, red
	beq $t0, $t1, position_attacked    # rojo = ya atacado (impacto)
	li $v0, 0                          # libre
	jr $ra
position_attacked:
	li $v0, 1                          # ya atacado
	jr $ra

# Obtener posición adyacente según dirección
get_adjacent_position:
	# Input: $a0 = posición base, $a1 = dirección (0=arriba, 1=derecha, 2=abajo, 3=izquierda)
	# Output: $v0 = posición adyacente
	
	beq $a1, 0, adjacent_up
	beq $a1, 1, adjacent_right
	beq $a1, 2, adjacent_down
	beq $a1, 3, adjacent_left
	
adjacent_up:
	addi $v0, $a0, -64       # una fila arriba
	jr $ra
	
adjacent_right:
	addi $v0, $a0, 4         # una columna derecha
	jr $ra
	
adjacent_down:
	addi $v0, $a0, 64        # una fila abajo
	jr $ra
	
adjacent_left:
	addi $v0, $a0, -4        # una columna izquierda
	jr $ra

# Atacar una posición específica (para la IA)
ai_attack_position:
	# Input: $a0 = posición a atacar
	# Output: $v0 = 1 si impacto, 0 si fallo, 2 si barco hundido
	
	# Guardar registros
	addi $sp, $sp, -12
	sw $s0, 0($sp)
	sw $s1, 4($sp)
	sw $ra, 8($sp)
	
	move $s0, $a0            # posición a atacar
	
	# Verificar si hay barco en el mapa del jugador 1
	lw $s1, player1_ship_map($s0)
	
	bgtz $s1, ai_hit_detected
	
	# FALLO
ai_miss_detected:
	lw $t0, white
	sw $t0, display($s0)     # pintar blanco
	li $v0, 0                # retornar fallo
	b ai_attack_position_done
	
	# IMPACTO
ai_hit_detected:
	lw $t0, red
	sw $t0, display($s0)     # pintar rojo
	
	# Incrementar puntuación de la IA (jugador 2)
	lw $t0, player2_score
	addi $t0, $t0, 1
	# Cap score at 34
	li $t1, 34
	ble $t0, $t1, ai_hit_score_ok
	move $t0, $t1
ai_hit_score_ok:
	sw $t0, player2_score
	
	# Decrementar salud del barco
	addi $t0, $s1, -1        # convertir ID a índice
	sll $t0, $t0, 2          # multiplicar por 4
	lw $t1, player1_ships_health($t0)
	addi $t1, $t1, -1
	sw $t1, player1_ships_health($t0)
	
	# Verificar si barco se hundió
	beq $t1, 0, ai_ship_sunk
	
	li $v0, 1                # retornar impacto
	b ai_attack_position_done
	
ai_ship_sunk:
	# Barco hundido - dar bonus a la IA y volver a hunting mode
	lw $t0, player2_score
	addi $t0, $t0, 5         # bonus por hundir
	# Cap score at 34
	li $t1, 34
	ble $t0, $t1, ai_sunk_score_ok
	move $t0, $t1
ai_sunk_score_ok:
	sw $t0, player2_score
	
	# Mostrar mensaje
	li $v0, 4
	la $a0, ship_sunk_msg
	syscall
	
	# Volver a hunting mode
	sw $zero, ai_mode
	sw $zero, ai_direction
	sw $zero, ai_steps_in_direction
	
	li $v0, 2                # retornar barco hundido
	
ai_attack_position_done:
	# Restaurar registros
	lw $s0, 0($sp)
	lw $s1, 4($sp)
	lw $ra, 8($sp)
	addi $sp, $sp, 12
	jr $ra

# Verificar si la IA ganó
check_ai_victory:
	# En PvE, verificar si la IA (jugador 2) alcanzó 34 puntos
	lw $s0, player2_score
	li $s1, 34
	bge $s0, $s1, ai_victory_achieved
	
	li $v0, 0                # no hay victoria
	jr $ra
	
ai_victory_achieved:
	li $v0, 1                # victoria de la IA
	jr $ra

# Mostrar victoria de la IA
ai_wins:
	# En PvE, la IA (CPU) ganó
	li $v0, 4
	la $a0, cpu_wins_msg
	syscall
	
	b show_final_score

# ============= SAIIDA DEL PROGRAMA =============
exit:
	li $v0, 10               # syscall para terminar programa
	syscall
