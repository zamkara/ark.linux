# Alga Source Code Architecture

The `alga` installer (`/src/main.rs`) is the operational core of the Apollo OS installation process. Built with Rust and GTK4 (via the `gtk4-rs` bindings and `libadwaita`), it manages system deployment while maintaining a highly responsive graphical interface.

## 1. Graphical User Interface (GUI) Integration
The primary UI initialization occurs within the `build_ui(app: &Application)` function.
- **`adw::ApplicationWindow`**: Instantiates the main application window utilizing modern Libadwaita design paradigms.
- **`gtk::DropDown`**: Used to present available target drives. The `get_host_drives()` function executes real-time block device enumeration using `lsblk -d -n -o NAME,SIZE,MODEL`. The resulting output is mapped into a `gtk::StringList` to populate the dropdown menu.
- **`gtk::TextView`**: Functions as an integrated terminal console, streaming `bootc` standard output to the user for full transparency.

## 2. Asynchronous Concurrency (Tokio & Glib Channels)
Executing long-running system commands (such as disk imaging) on the main GUI thread causes interface unresponsiveness. Alga prevents this by strictly decoupling background tasks from the main thread.

**Concurrency Implementation:**
1. **`glib::MainContext::channel`**: Establishes a message-passing channel between background asynchronous threads and the GTK main thread. The UI binds to this channel using `receiver.attach(...)`.
2. **`std::thread::spawn` & `tokio::runtime::Runtime`**: Initiating an installation spawns an isolated thread containing a dedicated `tokio` asynchronous runtime.
3. The `tokio` runtime asynchronously executes the `bootc install to-disk` command (`tokio::process::Command`), capturing `stdout` and `stderr` streams non-blockingly. Log lines are dispatched to the UI via `sender.send(...)`, allowing the `TextView` to update seamlessly.

## 3. Dynamic Progress Extraction (`sanitize_log`)
Alga dynamically calculates installation progress by parsing the raw data stream from the `bootc` backend via the `sanitize_log(raw: &str)` function.
- The function detects percentage indicators (e.g., `%`) within the stdout stream.
- It parses backward from the indicator to extract numeric values, returning them to the UI thread to update the application window title (`title4.set_label`).
- The function also filters excessive low-level I/O metrics and translates abstract backend operations into user-friendly status updates.

## 4. Asynchronous Cancellation Mechanisms
Alga implements robust interruption handling via the `tokio::select!` macro.
The macro concurrently awaits:
1. Standard output streams from the active installation process.
2. A cancellation signal (`kill_rx`) triggered by the user interacting with the "Cancel" or "Back" buttons in the UI.

If the `kill_rx` signal is received, the `tokio` runtime immediately terminates the child process (`child_install.kill()`) and executes the drive zeroing and unmounting protocols detailed in the Installer Mechanics documentation.
