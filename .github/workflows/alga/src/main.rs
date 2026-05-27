use libadwaita::prelude::*;
use gtk::prelude::*;
use libadwaita::{Application, ApplicationWindow, HeaderBar, PreferencesGroup, ActionRow};
use gtk::{
    Box, Button, Label, Orientation, ProgressBar, ScrolledWindow, Stack, StackTransitionType,
    TextView, CheckButton, Image,
};
use std::process::Stdio;
use tokio::io::{AsyncBufReadExt, BufReader};
use glib::clone;
use std::rc::Rc;
use std::cell::RefCell;
use tokio::sync::oneshot;

fn main() {
    let app = Application::builder()
        .application_id("com.zamkara.alga")
        .build();

    app.connect_startup(|_| {
        libadwaita::init();
    });

    app.connect_activate(build_ui);

    app.run();
}

fn build_ui(app: &Application) {
    let provider = gtk::CssProvider::new();
    provider.load_from_data("
        * { box-shadow: none !important; }
        .log-container, .log-container textview, .log-container text { 
            border-radius: 12px; 
        }
        .log-wrapper {
            border-radius: 12px;
            overflow: hidden;
            border: none;
        }
    ");
    gtk::style_context_add_provider_for_display(
        &gtk::gdk::Display::default().unwrap(),
        &provider,
        gtk::STYLE_PROVIDER_PRIORITY_APPLICATION,
    );

    let window = ApplicationWindow::builder()
        .application(app)
        .title("Apollo Installer")
        .default_width(360)  // Very narrow wizard
        .default_height(660) // Taller to fit content
        .build();

    let main_box = Box::new(Orientation::Vertical, 0);
    let header_bar = HeaderBar::new();
    
    let back_btn = Button::builder()
        .icon_name("go-previous-symbolic")
        .visible(false)
        .build();
    back_btn.add_css_class("flat");
    header_bar.pack_start(&back_btn);
    
    main_box.append(&header_bar);

    let stack = Stack::builder()
        .transition_type(StackTransitionType::SlideLeftRight)
        .build();

    let target_disk = Rc::new(RefCell::new(String::new()));
    let target_variant = Rc::new(RefCell::new(String::new()));
    let cancel_sender: Rc<RefCell<Option<oneshot::Sender<()>>>> = Rc::new(RefCell::new(None));
    let pulse_timeout: Rc<RefCell<Option<glib::SourceId>>> = Rc::new(RefCell::new(None));

    // --- Page 1: Disk Selection ---
    let page1_box = Box::new(Orientation::Vertical, 0);
    let content1 = Box::new(Orientation::Vertical, 18);
    content1.set_margin_top(16);
    content1.set_margin_bottom(24);
    content1.set_margin_start(24);
    content1.set_margin_end(24);
    content1.set_vexpand(true);
    
    let icon_path = if std::path::Path::new("/usr/share/icons/hicolor/scalable/apps/alga.svg").exists() {
        "/usr/share/icons/hicolor/scalable/apps/alga.svg"
    } else {
        "data/alga.svg"
    };

    let app_icon = Image::builder()
        .file(icon_path)
        .pixel_size(96)
        .halign(gtk::Align::Center)
        .margin_bottom(24)
        .build();
    
    let pref_group1 = PreferencesGroup::new();
    let host_drives = get_host_drives();
    let mut disk_radios: Vec<CheckButton> = Vec::new();
    let lsblk = std::process::Command::new("lsblk")
        .args(["-d", "-n", "-P", "-o", "NAME,SIZE,MODEL,RM,TRAN,TYPE"])
        .output();
        
    if let Ok(output) = lsblk {
        let stdout = String::from_utf8_lossy(&output.stdout);
        for line in stdout.lines() {
            if line.contains("TYPE=\"disk\"") && line.contains("RM=\"0\"") && !line.contains("TRAN=\"usb\"") 
                && !line.contains("NAME=\"loop") && !line.contains("NAME=\"zram") && !line.contains("NAME=\"ram") && !line.contains("NAME=\"sr") {
                let name = extract_val(line, "NAME");
                if host_drives.contains(&name) {
                    continue; // Skip the host's actively running drives
                }
                
                let size = extract_val(line, "SIZE");
                let model = extract_val(line, "MODEL");
                
                let display_title = if model.is_empty() { format!("Unknown Device (/dev/{})", name) } else { model };
                let display_subtitle = format!("/dev/{} - {}", name, size);
                let machine_name = format!("/dev/{}", name);
                
                let row = ActionRow::builder().title(&display_title).subtitle(&display_subtitle).build();
                let check = CheckButton::builder().build();
                check.set_widget_name(&machine_name);

                if let Some(first) = disk_radios.first() {
                    check.set_group(Some(first));
                }
                
                disk_radios.push(check.clone());
                row.add_prefix(&check);
                row.set_activatable_widget(Some(&check));
                pref_group1.add(&row);
            }
        }
    }
    if disk_radios.is_empty() {
        pref_group1.add(&ActionRow::builder().title("No physical drives found").build());
    }

    let title1 = Label::builder().label("<b>Welcome to Apollo OS</b>").use_markup(true).halign(gtk::Align::Center).build();
    title1.add_css_class("title-2");
    let subtitle1 = Label::builder().label("Please select the internal physical drive where you would like to install your new system. External drives are hidden for your safety.").wrap(true).justify(gtk::Justification::Fill).build();

    content1.append(&app_icon);
    content1.append(&title1);
    content1.append(&subtitle1);
    
    let spacer1 = Box::builder().vexpand(true).build();
    content1.append(&spacer1);
    content1.append(&pref_group1);
    
    let scroll1 = ScrolledWindow::builder().child(&content1).vexpand(true).build();
    page1_box.append(&scroll1);
    
    // Full width footer button
    let footer1 = Box::new(Orientation::Horizontal, 0);
    footer1.set_margin_top(16);
    footer1.set_margin_bottom(24);
    footer1.set_margin_start(24);
    footer1.set_margin_end(24);
    let next_btn1 = Button::builder().label("Next").css_classes(["suggested-action"]).hexpand(true).build();
    footer1.append(&next_btn1);
    page1_box.append(&footer1);
    stack.add_named(&page1_box, Some("page1"));

    // --- Page 2: Variant Selection ---
    let page2_box = Box::new(Orientation::Vertical, 0);
    let content2 = Box::new(Orientation::Vertical, 18);
    content2.set_margin_top(24);
    content2.set_margin_bottom(24);
    content2.set_margin_start(24);
    content2.set_margin_end(24);
    content2.set_vexpand(true);
    
    let title2 = Label::builder().label("<b>Select Variant</b>").use_markup(true).halign(gtk::Align::Center).build();
    title2.add_css_class("title-2");
    let subtitle2 = Label::builder().label("Choose the Apollo OS variant that best suits your hardware. The standard edition is ideal for Intel and AMD graphics, while the Nvidia edition comes pre-configured with proprietary drivers for optimal performance.").wrap(true).justify(gtk::Justification::Fill).build();
    
    let pref_group2 = PreferencesGroup::new();
    let row_var1 = ActionRow::builder().title("Apollo OS").subtitle("Standard edition for AMD/Intel graphics").build();
    let var1 = CheckButton::new();
    row_var1.add_prefix(&var1);
    row_var1.set_activatable_widget(Some(&var1));
    
    let row_var2 = ActionRow::builder().title("Apollo OS (Nvidia)").subtitle("Includes proprietary Nvidia drivers").build();
    let var2 = CheckButton::new();
    var2.set_group(Some(&var1));
    var1.set_active(true);
    row_var2.add_prefix(&var2);
    row_var2.set_activatable_widget(Some(&var2));
    
    pref_group2.add(&row_var1);
    pref_group2.add(&row_var2);
    
    content2.append(&title2);
    content2.append(&subtitle2);
    
    let spacer2 = Box::builder().vexpand(true).build();
    content2.append(&spacer2);
    content2.append(&pref_group2);
    page2_box.append(&content2);

    let footer2 = Box::new(Orientation::Horizontal, 0);
    footer2.set_margin_top(16);
    footer2.set_margin_bottom(24);
    footer2.set_margin_start(24);
    footer2.set_margin_end(24);
    let next_btn2 = Button::builder().label("Next").css_classes(["suggested-action"]).hexpand(true).build();
    footer2.append(&next_btn2);
    page2_box.append(&footer2);
    stack.add_named(&page2_box, Some("page2"));

    // --- Page 3: Detailed Confirmation ---
    let page3_box = Box::new(Orientation::Vertical, 0);
    let content3 = Box::new(Orientation::Vertical, 18);
    content3.set_margin_top(24);
    content3.set_margin_bottom(24);
    content3.set_margin_start(24);
    content3.set_margin_end(24);
    content3.set_vexpand(true);
    
    let title3 = Label::builder().label("<b>Terms of Installation</b>").use_markup(true).halign(gtk::Align::Start).build();
    title3.add_css_class("title-2");
    
    let info_text = "<b>Action Cannot Be Undone</b>\n\n\
                     You are about to install Apollo OS onto your physical drive. \
                     By proceeding, you authorize the installer to reformat the entire device.\n\n\
                     All partitions will be destroyed and all existing operating systems will be erased. \
                     Furthermore, all personal files, documents, and data on this drive will be permanently lost.\n\n\
                     Please ensure you have backed up any important data to an external drive or cloud storage before continuing.";
                     
    let info_label = Label::builder()
        .label(info_text)
        .use_markup(true)
        .wrap(true)
        .justify(gtk::Justification::Fill)
        .build();
        
    let pref_group3 = PreferencesGroup::new();
    let ack_row = ActionRow::builder().title("I understand that all data on my drive will be completely erased").build();
    ack_row.set_title_lines(0);
    let ack_check = CheckButton::new();
    ack_row.add_prefix(&ack_check);
    ack_row.set_activatable_widget(Some(&ack_check));
    pref_group3.add(&ack_row);
    
    content3.append(&title3);
    content3.append(&info_label);
    
    // Add spacer so checkbox is at the bottom of the scrollable area
    let spacer = Box::builder().vexpand(true).build();
    content3.append(&spacer);
    content3.append(&pref_group3);
    
    let scroll3 = ScrolledWindow::builder().child(&content3).vexpand(true).build();
    page3_box.append(&scroll3);
    
    let footer3 = Box::new(Orientation::Horizontal, 0);
    footer3.set_margin_top(16);
    footer3.set_margin_bottom(24);
    footer3.set_margin_start(24);
    footer3.set_margin_end(24);
    let erase_btn3 = Button::builder().label("Erase & Install").css_classes(["destructive-action"]).hexpand(true).sensitive(false).build();
    footer3.append(&erase_btn3);
    page3_box.append(&footer3);
    
    ack_check.connect_toggled(clone!(@weak erase_btn3 => move |cb| {
        erase_btn3.set_sensitive(cb.is_active());
    }));
    
    stack.add_named(&page3_box, Some("page3"));

    // --- Page 4: Progress (Rounded Log Window) ---
    let page4_box = Box::new(Orientation::Vertical, 0);
    let content4 = Box::new(Orientation::Vertical, 18);
    content4.set_margin_top(24);
    content4.set_margin_bottom(24);
    content4.set_margin_start(24);
    content4.set_margin_end(24);
    content4.set_vexpand(true);
    
    let title4 = Label::builder().label("<b>Installing Apollo OS...</b>").use_markup(true).halign(gtk::Align::Start).build();
    title4.add_css_class("title-2");
    
    let progress_bar = ProgressBar::builder().show_text(false).build();
    
    let text_view = TextView::builder()
        .editable(false)
        .cursor_visible(false)
        .wrap_mode(gtk::WrapMode::WordChar)
        .left_margin(12)
        .right_margin(12)
        .top_margin(12)
        .bottom_margin(12)
        .build();
    text_view.add_css_class("monospace");
    text_view.add_css_class("log-container");
    
    // Make the scrolled window look like a card with rounded corners
    let scroll4 = ScrolledWindow::builder()
        .child(&text_view)
        .vexpand(true)
        .build();
    scroll4.add_css_class("log-wrapper");
    
    content4.append(&title4);
    content4.append(&progress_bar);
    content4.append(&scroll4);
    page4_box.append(&content4);
    
    let footer4 = Box::new(Orientation::Horizontal, 0);
    footer4.set_margin_top(16);
    footer4.set_margin_bottom(24);
    footer4.set_margin_start(24);
    footer4.set_margin_end(24);
    let cancel_btn = Button::builder().label("Cancel Install").css_classes(["destructive-action"]).hexpand(true).build();
    footer4.append(&cancel_btn);
    page4_box.append(&footer4);
    
    stack.add_named(&page4_box, Some("page4"));

    // --- Page 5: Success ---
    let page5_box = Box::new(Orientation::Vertical, 0);
    let content5 = Box::new(Orientation::Vertical, 18);
    content5.set_margin_top(24);
    content5.set_margin_bottom(24);
    content5.set_margin_start(24);
    content5.set_margin_end(24);
    content5.set_vexpand(true);
    content5.set_halign(gtk::Align::Center);
    content5.set_valign(gtk::Align::Center);
    
    let title5 = Label::builder().label("<b>Installation Complete!</b>").use_markup(true).build();
    title5.add_css_class("title-1");
    let success_lbl = Label::new(Some("Apollo OS is successfully installed."));
    content5.append(&title5);
    content5.append(&success_lbl);
    page5_box.append(&content5);
    
    let footer5 = Box::new(Orientation::Horizontal, 12);
    footer5.set_homogeneous(true); // Make both buttons equal width
    footer5.set_margin_top(16);
    footer5.set_margin_bottom(24);
    footer5.set_margin_start(24);
    footer5.set_margin_end(24);
    let stay_btn = Button::builder().label("Stay Live").hexpand(true).build();
    let reboot_btn = Button::builder().label("Reboot").css_classes(["suggested-action"]).hexpand(true).build();
    footer5.append(&stay_btn);
    footer5.append(&reboot_btn);
    page5_box.append(&footer5);
    stack.add_named(&page5_box, Some("page5"));

    // --- Navigation Logic ---
    
    stack.connect_visible_child_notify(clone!(@weak back_btn => move |s| {
        let current = s.visible_child_name().unwrap_or_default();
        back_btn.set_visible(current == "page2" || current == "page3");
    }));

    back_btn.connect_clicked(clone!(@weak stack => move |_| {
        let current = stack.visible_child_name().unwrap_or_default();
        if current == "page2" {
            stack.set_visible_child_name("page1");
        } else if current == "page3" {
            stack.set_visible_child_name("page2");
        }
    }));
    
    next_btn1.connect_clicked(clone!(@weak stack, @strong disk_radios, @strong target_disk => move |_| {
        let mut selected = String::new();
        for cb in &disk_radios {
            if cb.is_active() {
                selected = cb.widget_name().to_string();
            }
        }
        if !selected.is_empty() {
            *target_disk.borrow_mut() = selected;
            stack.set_visible_child_name("page2");
        }
    }));
    
    next_btn2.connect_clicked(clone!(@weak stack, @strong target_variant, @weak var1 => move |_| {
        if var1.is_active() {
            *target_variant.borrow_mut() = "ghcr.io/zamkara/apollo.builder:apollo".to_string();
        } else {
            *target_variant.borrow_mut() = "ghcr.io/zamkara/apollo.builder:apollo-nvidia".to_string();
        }
        stack.set_visible_child_name("page3");
    }));
    
    cancel_btn.connect_clicked(clone!(@strong cancel_sender, @weak stack, @weak cancel_btn => move |_| {
        if let Some(sender) = cancel_sender.borrow_mut().take() {
            let _ = sender.send(()); // Send kill signal
        } else {
            // Act as Back button if installation is already finished/failed
            stack.set_visible_child_name("page1");
            cancel_btn.set_label("Cancel Install");
            cancel_btn.add_css_class("destructive-action");
            cancel_btn.remove_css_class("suggested-action");
        }
    }));
    
    erase_btn3.connect_clicked(clone!(@weak stack, @weak text_view, @weak progress_bar, @weak cancel_btn, @weak title4, @strong target_disk, @strong target_variant, @strong cancel_sender, @strong pulse_timeout => move |_| {
        stack.set_visible_child_name("page4");
        cancel_btn.set_visible(true);
        cancel_btn.set_label("Cancel Install");
        cancel_btn.add_css_class("destructive-action");
        cancel_btn.remove_css_class("suggested-action");
        
        let source_id = glib::timeout_add_local(std::time::Duration::from_millis(100), clone!(@weak progress_bar => @default-return glib::ControlFlow::Break, move || {
            progress_bar.pulse();
            glib::ControlFlow::Continue
        }));
        *pulse_timeout.borrow_mut() = Some(source_id);
        
        let disk = target_disk.borrow().clone();
        let variant = target_variant.borrow().clone();
        
        let (sender, receiver) = glib::MainContext::channel(glib::Priority::DEFAULT);
        let (kill_tx, mut kill_rx) = oneshot::channel::<()>();
        *cancel_sender.borrow_mut() = Some(kill_tx);
        
        receiver.attach(None, clone!(@weak text_view, @weak progress_bar, @weak stack, @weak cancel_btn, @weak title4, @strong cancel_sender, @strong pulse_timeout => @default-return glib::ControlFlow::Break, move |msg: String| {
            if msg.starts_with("EOF_") {
                if let Some(id) = pulse_timeout.borrow_mut().take() {
                    id.remove();
                }
            }
            
            if msg == "EOF_SUCCESS" {
                stack.set_visible_child_name("page5");
                return glib::ControlFlow::Break;
            } else if msg == "EOF_CANCEL" {
                text_view.buffer().insert(&mut text_view.buffer().end_iter(), "\n[Installation Cancelled]\n");
                stack.set_visible_child_name("page1"); 
                return glib::ControlFlow::Break;
            } else if msg == "EOF_ERROR" {
                progress_bar.add_css_class("error");
                
                let _ = cancel_sender.borrow_mut().take();
                cancel_btn.set_label("Back to Menu");
                cancel_btn.remove_css_class("destructive-action");
                cancel_btn.add_css_class("suggested-action");
                
                text_view.buffer().insert(&mut text_view.buffer().end_iter(), "\n[Installation Failed]\n");
                return glib::ControlFlow::Break;
            }
            
            let (pct, clean_msg) = match sanitize_log(&msg) {
                Some((p, m)) => (p, m),
                None => return glib::ControlFlow::Continue,
            };
            
            if let Some(p) = pct {
                title4.set_label(&format!("<b>{}% Installing...</b>", p));
            }
            
            let buffer = text_view.buffer();
            let mut iter = buffer.end_iter();
            buffer.insert(&mut iter, &format!("{}\n", clean_msg));
            
            let mark = buffer.create_mark(None, &buffer.end_iter(), false);
            text_view.scroll_to_mark(&mark, 0.0, false, 0.0, 0.0);
            
            glib::ControlFlow::Continue
        }));
        
        std::thread::spawn(move || {
            let rt = tokio::runtime::Runtime::new().unwrap();
            rt.block_on(async {
                let bootc_cmd = format!(
                    "killall -9 bootc skopeo 2>/dev/null || true; for p in {}*; do umount -l $p 2>/dev/null || true; done; umount -l /run/bootc/mounts/rootfs 2>/dev/null || true; btrfs device scan --forget 2>/dev/null || true; wipefs -af {}* 2>/dev/null || true; bootc install to-disk --generic-image --wipe --filesystem btrfs --bootloader none --source-imgref docker://{} {}", 
                    disk, disk, variant, disk
                );
                
                let mut child_install = tokio::process::Command::new("pkexec")
                    .args(["bash", "-c", &bootc_cmd])
                    .stdout(Stdio::piped())
                    .stderr(Stdio::piped())
                    .spawn()
                    .expect("Failed to spawn pkexec bootc install");
                    
                let mut stdout_inst = BufReader::new(child_install.stdout.take().unwrap()).lines();
                let mut stderr_inst = BufReader::new(child_install.stderr.take().unwrap()).lines();

                loop {
                    tokio::select! {
                        _ = &mut kill_rx => {
                            let _ = child_install.kill().await;
                            
                            let _ = sender.send("Cleaning up and formatting drive to unallocated state...".to_string());
                            let cleanup_cmd = format!(
                                "killall -9 bootc skopeo 2>/dev/null || true; for p in {}*; do umount -l $p 2>/dev/null || true; done; btrfs device scan --forget 2>/dev/null || true; wipefs -af {}* 2>/dev/null || true; dd if=/dev/zero of={} bs=1M count=10 2>/dev/null || true; partprobe {} 2>/dev/null || true", 
                                disk, disk, disk, disk
                            );
                            let _ = tokio::process::Command::new("pkexec")
                                .args(["bash", "-c", &cleanup_cmd])
                                .output()
                                .await;
                                
                            let _ = sender.send("EOF_CANCEL".to_string());
                            return;
                        }
                        line = stdout_inst.next_line() => {
                            match line {
                                Ok(Some(l)) => { let _ = sender.send(l); }
                                Ok(None) => break,
                                Err(_) => break,
                            }
                        }
                        line = stderr_inst.next_line() => {
                            if let Ok(Some(l)) = line { let _ = sender.send(l); }
                        }
                    }
                }
                
                let status = child_install.wait().await;
                match status {
                    Ok(s) if s.success() => {
                        let _ = sender.send("95% Installing bootloader...".to_string());
                        let bootloader_cmd = format!(
                            "EFI_PART=$(lsblk -rno PATH,PARTTYPE {} | grep -i 'c12a7328-f81f-11d2-ba4b-00a0c93ec93b' | head -n1 | awk '{{print $1}}'); if [ -n \"$EFI_PART\" ]; then mkdir -p /tmp/efi_mnt; umount -l $EFI_PART 2>/dev/null || true; mount $EFI_PART /tmp/efi_mnt && bootctl install --esp-path=/tmp/efi_mnt && umount /tmp/efi_mnt; fi",
                            disk
                        );
                        let _ = tokio::process::Command::new("pkexec")
                            .args(["bash", "-c", &bootloader_cmd])
                            .output()
                            .await;
                        let _ = sender.send("EOF_SUCCESS".to_string());
                    },
                    _ => {
                        let _ = sender.send("EOF_ERROR".to_string());
                    }
                }
            });
        });
    }));
    
    stay_btn.connect_clicked(|_| {
        std::process::exit(0);
    });
    
    reboot_btn.connect_clicked(|_| {
        let _ = std::process::Command::new("sudo").arg("reboot").status();
    });

    main_box.append(&stack);
    window.set_content(Some(&main_box));
    window.present();
}

fn extract_val(line: &str, key: &str) -> String {
    let k = format!("{}=\"", key);
    if let Some(start) = line.find(&k) {
        let sub = &line[start + k.len()..];
        if let Some(end) = sub.find('"') {
            return sub[..end].to_string();
        }
    }
    String::new()
}

fn get_host_drives() -> Vec<String> {
    let mut drives = Vec::new();
    if let Ok(findmnt) = std::process::Command::new("findmnt").args(["-n", "-v", "-o", "SOURCE", "/"]).output() {
        let source = String::from_utf8_lossy(&findmnt.stdout).trim().to_string();
        if !source.is_empty() {
            if let Ok(lsblk) = std::process::Command::new("lsblk").args(["-s", "-n", "-P", "-o", "NAME,TYPE", &source]).output() {
                let stdout = String::from_utf8_lossy(&lsblk.stdout);
                for line in stdout.lines() {
                    if line.contains("TYPE=\"disk\"") {
                        let name = extract_val(line, "NAME");
                        if !name.is_empty() {
                            drives.push(name);
                        }
                    }
                }
            }
        }
    }
    drives
}

fn sanitize_log(raw: &str) -> Option<(Option<u32>, String)> {
    if raw.trim().is_empty() {
        return None;
    }
    
    let trimmed = raw.trim();
    let lower = trimmed.to_lowercase();
    
    let mut extracted_pct = None;
    if let Some(idx) = lower.find('%') {
        let mut start = idx;
        let bytes = lower.as_bytes();
        while start > 0 && bytes[start - 1].is_ascii_digit() {
            start -= 1;
        }
        if start < idx {
            if let Ok(val) = lower[start..idx].parse::<u32>() {
                extracted_pct = Some(val);
            }
        }
    }
    
    let hide_prefixes = [
        "Wiping",
        "Block setup:",
        "Size:",
        "Serial:",
        "Model:",
        "Partitions:",
        "Disk /dev",
        "Disk model:",
        "Units:",
        "Sector size",
        "I/O size",
        ">>> Script header",
        "New situation:",
        "Disklabel type:",
        "Disk identifier:",
        "Device", // matches "Device       Start"
        "The partition table has been altered",
        "Calling ioctl()",
        "Syncing disks",
        "> mkfs",
        "layers already present",
        "Bootloader:",
        "Checking that no-one is using this disk",
        "/dev/",
        "program: \"",
        "args: [",
        "create_pidfd:",
        "\"/dev/"
    ];
    
    for prefix in hide_prefixes.iter() {
        if trimmed.starts_with(prefix) {
            return None;
        }
    }
    
    let hide_exact = [
        "}",
        "],",
        "\"wipefs\",",
        "\"-a\","
    ];
    for ext in hide_exact.iter() {
        if trimmed == *ext {
            return None;
        }
    }
    
    if lower.contains("bytes were erased") || lower.contains("calling ioctl") || lower.contains("failed to run command") || lower.contains("command {") {
        return None;
    }

    // 2. Whitelist and translate friendly messages
    if lower.contains("installing image:") {
        return Some((Some(5), "Starting installation process...".to_string()));
    }
    if lower.contains("created a new gpt disklabel") {
        return Some((Some(15), "Configuring partition tables...".to_string()));
    }
    if lower.contains("creating root filesystem") {
        return Some((Some(30), "Formatting system partitions...".to_string()));
    }
    if lower.contains("creating esp filesystem") {
        return Some((Some(40), "Formatting boot partition...".to_string()));
    }
    if lower.contains("initializing ostree layout") {
        return Some((Some(50), "Initializing immutable system layout...".to_string()));
    }
    if lower.contains("deploying container image") {
        return Some((Some(70), "Deploying operating system image (this may take a while)...".to_string()));
    }
    
    // 3. Error handling
    if lower.contains("error:") || lower.contains("failed") {
        if lower.contains("network is unreachable") || lower.contains("unexpected end of file") {
            return Some((None, "Installation Error: Network connection dropped. Please check your internet and try again.".to_string()));
        }
        if lower.contains("device is mounted") || lower.contains("is mounted") || lower.contains("resource busy") || lower.contains("device or resource busy") {
            return Some((None, "Installation Error: The target drive is currently busy. Please reboot and try again.".to_string()));
        }
        if lower.contains("bootupd is required") {
            return Some((None, "Installation Error: Missing bootloader components (bootupd).".to_string()));
        }
        
        // Fallback error cleaner
        if let Some(idx) = lower.find("error:") {
            let clean = trimmed[idx..].to_string();
            let mut chars = clean.chars();
            let cap = match chars.next() {
                None => String::new(),
                Some(f) => f.to_uppercase().collect::<String>() + chars.as_str(),
            };
            return Some((None, format!("Installation Failed: {}", cap)));
        }
        return Some((None, format!("Installation Failed: {}", trimmed)));
    }

    // Pass through anything that isn't matched
    Some((extracted_pct, trimmed.to_string()))
}
