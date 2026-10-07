# Review alur dan seluruh keluarga Python

## Jalur motor utama

`odom_publisher.py` menerima Twist, menyimpan linear_x, linear_y, angular_z, lalu mengubah koordinat ke speed dan direction. Constructor memasang wheelbase=0,216, track_width=0,195, wheel_diameter=0,097 m. Callback app membatasi translasi ±0,2 m/s dan rotasi ±0,5 rad/s. Callback utama tidak menggunakan clamp app tersebut.

`mecanum.py` menghitung vx=speed*sin(direction), vy=speed*cos(direction), vp=omega*(wheelbase+track_width)/2, lalu empat nilai wheel speed. RPS adalah wheel speed/(pi*diameter). Constructor default file ini 0,206/0,194/0,0965 m, tetapi odom mengoverride menjadi nilai di atas. Jadi angka dokumentasi valid untuk instansiasi odom, bukan default kelas.

`ros_robot_controller_node.py` mengambil daftar MotorState dan memanggil Board.set_motor_speed. Pada startup node mengirim kecepatan nol. Tidak ada pemanggilan motor-enable, motor PID configuration atau upload firmware dalam jalur ini. PWM servo offset pada startup menyasar servo dan tidak membuka motor.

`ros_robot_controller_sdk.py` membuka serial 1.000.000 baud, RTS=False, DTR=False, lalu thread penerima. enable_reception hanya flag lokal Python, tidak mengirim perintah enable motor. get_battery membaca SYS subtype 0x04, uint16 little-endian. set_motor_speed mengirim function=3, subcommand=1, count, lalu pasangan uint8(id-1) dan float32 RPS.

Frame: AA 55 FUNC LEN DATA CRC. CRC dimulai pada FUNC, tidak termasuk header. Lookup cocok dengan algoritma reflected polynomial 0x8C, initial zero. Empat motor memiliki payload 22 byte dan total 27 byte. Satu motor payload 7 byte dan total 12 byte. Unit bukan RPM atau duty PWM.

## Catatan posisi motor

Label posisi fisik pada motor_data_flow.md tidak boleh dijadikan kepastian. Diagram komentar mecanum.py memperlihatkan M1/M2 di sisi kiri dan M3/M4 di kanan, berbeda dari daftar posisi M2/M3 dalam dokumen. Tes memakai ID dan tanda yang benar menurut source, yaitu maju +,+,-,-. Posisi fisik harus mengikuti kabel/label board aktual. Salah label posisi tidak menjelaskan semua motor diam.

## Keluarga file lainnya

| File/keluarga | Peran |
|---|---|
| jetauto_sdk/ackermann.py | Kinematika chassis Ackermann alternatif, tidak digunakan cmd_vel mecanum di paket ini |
| jetauto_sdk/pid.py | PID host utilitas, tidak sama dengan firmware PID motor STM |
| jetauto_sdk/common.py, misc.py | Utilitas matematika/image dan helper umum |
| jetauto_sdk/fps.py | Pengukur frame rate |
| jetauto_sdk/button.py, led.py | Helper peripheral, bukan jalur command motor SDK |
| jetauto_kinematics/transform.py | Transformasi koordinat arm |
| jetauto_kinematics/kinematics_control.py, kinematics_demo.py | Kontrol/demo arm dengan kinematika, bukan chassis motor |
| search_kinematics_solutions_node.py | Node pencari solusi arm |
| controller_manager.py | Pengelola controller servo ROS |
| joint_state_publisher.py | Publikasi keadaan joint servo |
| joint_controller.py, joint_position_controller.py | Abstraksi dan kontrol posisi servo |
| joint_trajectory_action_controller.py | Eksekusi trajectory servo |
| action_group_runner.py | Menjalankan action group servo |
| bus_servo_control.py | Akses bus servo |
| hiwonder_servo_io.py | IO protocol servo |
| hiwonder_servo_serialproxy.py | Proxy koneksi servo |
| setup.py | Metadata instalasi package ROS/Python |
| __init__.py | Inisialisasi namespace package |

Daftar lengkap 37 file dengan methods/imports dan lokasi baris ada dalam PYTHON_FILE_CATALOG.md. ROS messages, services, CMake dan launch file tersimpan di original. Python-only laptop test tidak memerlukan rospy, generated message atau library kinematika arm.

## Temuan yang tidak berada pada jalur motor

Rule udev dalam ZIP mengandung trailing karakter yang mencurigakan pada baris ID_MM_PORT_IGNORE. Ini perlu dibenahi untuk Linux bila digunakan, tetapi tidak menjelaskan COM9 Windows. Mengganti symlink /dev/rrc juga tidak mengubah motor firmware. Keberhasilan buzzer memvalidasi satu handler, bukan seluruh motor PID atau rail daya.

Tidak ada source STM C/C++, schematic atau binary firmware dalam driver Python ini. Ia tidak dapat membuktikan implementasi callback motor, encoder, interlock, ADC voltage atau driver enable pada board.
