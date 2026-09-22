# Godot 4.x Mini-Games Collection 🎮

Repositori ini berisi kumpulan *project* eksperimental dan *prototype* *game* yang dibangun menggunakan **Godot Engine 4.x**. Saat ini, terdapat dua *project* utama dengan tingkat kompleksitas dan *genre* yang berbeda.

## 📁 Struktur Folder

```text
📦 repository-name
 ┣ 📂 reality_decay    # Prototype game UI/Manajemen Waktu
 ┗ 📂 pacman_clone     # Game Arcade 2D dasar

```

---

## 🕹️ Project 1: Reality Decay (UI / Time-Management Puzzle)

Sebuah *prototype game* berbasis antarmuka (UI-based) di mana pemain bertindak sebagai operator stasiun luar angkasa. Pemain harus mengelola *resource* (Power) dan mengambil keputusan cepat untuk menyelamatkan dimensi/kota dari kehancuran (*Reality Decay*).

* **Status:** *Greyboxing / Prototyping* (Kerangka logika UI sudah berjalan, aset visual belum diimplementasikan).
* **Mekanik Utama:**
* Manajemen *Timer* (Persentase nyawa kota menurun secara otomatis).
* Interaksi UI (Memutar *dial* / *slider* dan menekan tombol aksi).
* Manajemen *Resource* (Setiap aksi mengurangi bar energi/Power).


* **Fokus Pembelajaran:** Manipulasi Control Nodes (UI Godot), *Signals*, Timer, dan *State Management*.

## 🟡 Project 2: Pac-Man Clone (Simple 2D Arcade)

Sebuah *clone* dari *game* klasik Pac-Man yang dirancang seminimalis mungkin. *Project* ini dibuat sebagai arena bermain untuk memahami fundamental mekanik 2D di Godot.

* **Status:** *Playable* (Mekanik dasar).
* **Mekanik Utama:**
* Pergerakan 4 arah (CharacterBody2D).
* Desain level labirin menggunakan (TileMapLayer).
* Sistem *collectibles* (Memakan titik/pellet untuk menambah skor menggunakan Area2D).
* AI musuh (*Ghost*) dengan pergerakan pantul/patroli dasar.


* **Fokus Pembelajaran:** Fundamental fisika 2D, deteksi tabrakan (*Collision*), manajemen *Scene/Node*, dan pembaruan UI (Skor).

---

## 🚀 Cara Menjalankan Project

Karena kedua *game* ini berada di folder yang terpisah, sistem Godot akan membacanya sebagai dua *project* yang berbeda.

1. Pastikan **Godot Engine (versi 4.x)** sudah ter-install di sistem Anda (Linux/Windows/macOS).
2. Buka aplikasi Godot (Project Manager).
3. Klik tombol **Import**.
4. Klik **Browse** dan arahkan ke folder *game* yang ingin dimainkan (misal: masuk ke folder `pacman_clone`).
5. Pilih file `project.godot` yang ada di dalam folder tersebut, lalu klik **Import & Edit**.
6. Setelah *editor* terbuka, tekan **F5** atau klik tombol **Play (▶️)** di pojok kanan atas untuk menjalankan *game*.

## 🛠️ Tech Stack

* **Engine:** Godot Engine 4.x
* **Bahasa Scripting:** GDScript
* **Platform:** PC (Desktop)
