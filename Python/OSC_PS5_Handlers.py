# === OSC_PS5_HANDLERS.PY ===

# 1. Importazione librerie
import pygame
import time
import threading

from pythonosc.udp_client import SimpleUDPClient
from pythonosc.dispatcher import Dispatcher
from pythonosc.osc_server import BlockingOSCUDPServer

# 2. Inizializzaione pygame e rilevamento joystick
pygame.init()
pygame.joystick.init()

if pygame.joystick.get_count() == 0:
    print("❌ Nessun controller trovato")
    exit()

joystick = pygame.joystick.Joystick(0)
joystick.init()

print(f"✅ Controller collegato: {joystick.get_name()}")

time.sleep(2) 

# 3. Setup OSC (IP e porta di SuperCollider)
client = SimpleUDPClient("127.0.0.1", 12000)

# 4. Mappatura pulsanti ed assi

# 4.1 Mappatura pulsanti 
BUTTON_CROSS = 0        # Croce
BUTTON_CIRCLE = 1       # Cerchio
BUTTON_SQUARE = 2       # Quadrato
BUTTON_TRIANGLE = 3     # Triangolo
BUTTON_SHARE = 4        # Share
BUTTON_PS = 5           # PS Button
BUTTON_OPTIONS = 6      # Options
BUTTON_L3 = 7           # L3
BUTTON_R3 = 8           # R3
BUTTON_L1 = 9           # L1
BUTTON_R1 = 10          # R1
BUTTON_DPAD_UP = 11     # Freccia su
BUTTON_DPAD_DOWN = 12   # Freccia giù
BUTTON_DPAD_LEFT = 13   # Freccia sinistra
BUTTON_DPAD_RIGHT = 14  # Freccia destra
BUTTON_TOUCHPAD = 15    # Touchpad
BUTTON_MUTE = 16        # Mute

# 4.2 Mappatura assi
AXIS_LEFT_STICK_X = 0   # Stick sinistro X
AXIS_LEFT_STICK_Y = 1   # Stick sinistro Y
AXIS_RIGHT_STICK_X = 2  # Stick destro X
AXIS_RIGHT_STICK_Y = 3  # Stick destro Y
AXIS_L2 = 4             # L2
AXIS_R2 = 5             # R2

# 5. Inizializzazione parametri 
glide = 1.0            # 1.0 = neutro, 2.0 = +1 ottava, 0.5 = -1 ottava
glideTime = 0.2        # tempo del glide in secondi
last_glide = None
last_glideTime = None


lfoFreq = 0.0
lfoDepth = 0.0
lfoDepth_step = 0.01
cutoff = 20
cutoff_step = 0.3

# 6. Inizializzazione cache 
last_lfoFreq = None
last_lfoDepth = None
last_cutoff = None
last_sendLevel1 = None
last_sendLevel2 = None
last_sendLevel3 = None
last_sendLevel4 = None

# GPT
def update_lfoFreq(addr, value):
    global lfoFreq, last_lfoFreq
    lfoFreq = max(0, min(20, value))
    last_lfoFreq = lfoFreq

def update_lfoDepth(addr, value):
    global lfoDepth, last_lfoDepth
    lfoDepth = max(0, min(1.0, value))
    last_lfoDepth = lfoDepth

def update_cutoff(addr, value):
    global cutoff, last_cutoff
    cutoff = max(0, min(20, value))
    last_cutoff = cutoff

def update_sendLevel1(addr, value):
    global sendLevel1, last_sendLevel1
    sendLevel1 = max(0, min(1, value))
    last_sendLevel1 = sendLevel1

def update_sendLevel2(addr, value):
    global sendLevel2, last_sendLevel2
    sendLevel2 = max(0, min(1, value))
    last_sendLevel2 = sendLevel2

def update_sendLevel3(addr, value):
    global sendLevel3, last_sendLevel3
    sendLevel3 = max(0, min(1, value))
    last_sendLevel3 = sendLevel3

def update_sendLevel4(addr, value):
    global sendLevel4, last_sendLevel4
    sendLevel4 = max(0, min(1, value))
    last_sendLevel4 = sendLevel4

# 7. Funzione ottimizzazione invio OSC
def send_if_changed(path, value, last_value, threshold=0.001):
    if last_value is None or abs(value - last_value) > threshold:
        client.send_message(path, value)
        return True, value 
    return False, last_value

# 8. Aggiornamento stato controller
print("🎮 Pronto. Premere PS per uscire.")
force_sync = True  # Forza sincronizzazione al primo loop

# GPT
dispatcher = Dispatcher()
dispatcher.map("/controller/lfoFreq", update_lfoFreq)
dispatcher.map("/controller/lfoDepth", update_lfoDepth)
dispatcher.map("/controller/cutoff", update_cutoff)
dispatcher.map("/controller/sendLevel1", update_sendLevel1)
dispatcher.map("/controller/sendLevel2", update_sendLevel2)
dispatcher.map("/controller/sendLevel3", update_sendLevel3)
dispatcher.map("/controller/sendLevel4", update_sendLevel4)

def start_osc_server():
    server = BlockingOSCUDPServer(("127.0.0.1", 12001), dispatcher)
    server.serve_forever()

osc_thread = threading.Thread(target=start_osc_server, daemon=True)
osc_thread.start()

while True:
    pygame.event.pump()

    updated = False  # flag per sapere se qualcosa è cambiato

    now = time.time()

    # === USCITA SICURA: PS + OPTIONS ===
    if joystick.get_button(BUTTON_PS):
        print("🛑 Combinazione di uscita rilevata. Termine script.")
        break

    # 8.1 BUTTONS

    # 8.1.1 Debounced Cutoff (Freccia destra = incrementa, Freccia sinistra = decrementa)
    if joystick.get_button(BUTTON_DPAD_RIGHT):
        cutoff += cutoff_step
        last_cutoff_change = now
    elif joystick.get_button(BUTTON_DPAD_LEFT):
        cutoff -= cutoff_step
        last_cutoff_change = now
    cutoff = max(0, min(20, cutoff))
    sent, last_cutoff = send_if_changed("/controller/cutoff", cutoff, last_cutoff, threshold=0 if force_sync else 1e-6)
    if force_sync:
        force_sync = False
    updated = updated or sent
    
    # 8.1.2 Debounced lfoDepth (L1 = decrementa, R1 = incrementa)
    if joystick.get_button(BUTTON_R1):
        lfoDepth += lfoDepth_step
        last_lfoDepth_change = now
    elif joystick.get_button(BUTTON_L1):
        lfoDepth -= lfoDepth_step
        last_lfoDepth_change = now
    lfoDepth = max(0, min(1.0, lfoDepth))
    sent, last_lfoDepth = send_if_changed("/controller/lfoDepth", lfoDepth, last_lfoDepth, threshold=0 if force_sync else 1e-6)
    if force_sync:
        force_sync = False
    updated = updated or sent

    # 8.1.3 Glide (Freccia su = +1 ottava, Freccia giù = -1 ottava, altrimenti 1.0)
    if joystick.get_button(BUTTON_DPAD_UP):
        glide = 2.0
    elif joystick.get_button(BUTTON_DPAD_DOWN):
        glide = 0.5
    else:
        glide = 1.0

    sent1, last_glide = send_if_changed("/controller/glide", glide, last_glide)
    #sent2, last_glideTime = send_if_changed("/controller/glideTime", glideTime, last_glideTime)
    updated = updated or sent1 


    # 8.1.4 Modalità Mono/Poly
    if joystick.get_button(BUTTON_CIRCLE):
        client.send_message("/controller/monoMode", 1)
        #client.send_message("/controller/polyMode", 0)
        print("🎚️ Modalità Mono selezionata")
        #time.sleep(0.2)  # debounce

    elif joystick.get_button(BUTTON_SQUARE):
        #client.send_message("/controller/monoMode", 0)
        client.send_message("/controller/polyMode", 1)
        print("🎚️ Modalità Poly selezionata")
        #time.sleep(0.2)  # debounce


    # 8.2 AXIS

    # 8.2.1 LFO Frequency (R2 - L2)
    l2 = (joystick.get_axis(AXIS_L2) + 1) / 2
    r2 = (joystick.get_axis(AXIS_R2) + 1) / 2
    delta = r2 - l2
    lfoFreq += delta * 0.5
    lfoFreq = max(0, min(20, lfoFreq))
    sent, last_lfoFreq = send_if_changed("/controller/lfoFreq", lfoFreq, last_lfoFreq)
    updated = updated or sent

    # 8.2.2 Riverbero (Stick sinistro Y)
    ly_raw = joystick.get_axis(AXIS_LEFT_STICK_Y)

    # 1) per la GUI: mando raw fra –1 e +1 per sapere direzione e intensità
    client.send_message("/controller/sendLevel1Raw", ly_raw)

    # Livello riverbero (massimo a ±1, minimo a 0)
    sendLevel1 = abs(ly_raw)
    sent1, last_sendLevel1 = send_if_changed("/controller/sendLevel1", sendLevel1, last_sendLevel1)

    # Room size: 0.5 al centro, sale a 1.0 con ly = +1, scende a 0.0 con ly = -1
    roomSize = 0.5 - (ly_raw * 0.5)
    roomSize = max(0, min(1, roomSize))  # clip tra 0 e 1
    sent2, _ = send_if_changed("/controller/r_roomsize", roomSize, None)

    updated = updated or sent1 or sent2


    # 8.2.3 Delay (Stick sinistro X)
    lx_raw = joystick.get_axis(AXIS_LEFT_STICK_X)

    client.send_message("/controller/sendLevel2Raw", lx_raw)

    # Livello delay (massimo a ±1, minimo a 0)
    sendLevel2 = abs(lx_raw)
    sent3, last_sendLevel2 = send_if_changed("/controller/sendLevel2", sendLevel2, last_sendLevel2)

    # Delay Feedback: 0.5 al centro, sale a 1.0 con lx = +1, scende a 0.0 con lx = -1
    delayFeedback = 0.5 + (lx_raw * 0.5)
    delayFeedback = max(0, min(1, delayFeedback))  # clip tra 0 e 1
    sent4, _ = send_if_changed("/controller/de_feedback", delayFeedback, None)

    updated = updated or sent3 or sent4



    # 8.2.4 Flanger (Stick destro Y)
    ry_raw = joystick.get_axis(AXIS_RIGHT_STICK_Y)
    
    client.send_message("/controller/sendLevel3Raw", ry_raw)

    sendLevel3 = abs(ry_raw)
    sent, last_sendLevel3 = send_if_changed("/controller/sendLevel3", sendLevel3, last_sendLevel3)
    updated = updated or sent



    # 8.2.5 Distortion (Stick destro X) 
    rx_raw = joystick.get_axis(AXIS_RIGHT_STICK_X)

    client.send_message("/controller/sendLevel4Raw", rx_raw)

    # Livello distorsione (massimo a ±1, minimo a 0)
    sendLevel4 = abs(rx_raw)
    sent7, last_sendLevel4 = send_if_changed("/controller/sendLevel4", sendLevel4, last_sendLevel4)
    
    # Distortion Tone: 0.5 al centro, sale a 1.0 con rx = +1, scende a 0.0 con rx = -1
    distortionTone = 0.5 + (rx_raw * 0.5)
    distortionTone = max(0, min(1, distortionTone))  # clip tra 0 e 1
    sent8, _ = send_if_changed("/controller/di_tone", distortionTone, None)

    updated = updated or sent7 or sent8

    if updated:
        print(f"LFO: {lfoFreq:.2f}, lfoDepth: {lfoDepth:.2f}, Cutoff: {cutoff:.2f}, Reverb Send: {sendLevel1:.2f}, Room Size: {roomSize:.2f}, Delay: {sendLevel2:.2f}, DelayFeedback: {delayFeedback:.2f},Flanger: {sendLevel3:.2f}, Distortion: {sendLevel4:.2f}, DistortionTone: {distortionTone:.2f},")

    time.sleep(0.05)

