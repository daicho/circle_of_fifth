import ddf.minim.*;
import ddf.minim.ugens.*;

public class Note {
  private float frequency;
  private float set_volume;
  private float fade_time;
  private float fade_speed;
  private AudioOutput out;
  private Oscil oscil;
  private int prev_time;
  private float volume = 0;
  private boolean playing = false;
  private boolean fading = false;

  public Note(float frequency, float set_volume, float fade_time, AudioOutput out) {
    this.frequency = frequency;
    this.set_volume = set_volume;
    this.fade_time = fade_time;
    this.fade_speed = set_volume / fade_time / 1000;
    this.out = out;
    this.oscil = new Oscil(frequency, volume, Waves.SINE);
  }

  // 再生
  public void play() {
    if (playing) return;

    if (fading)
      oscil.unpatch(out);

    volume = set_volume;
    oscil = new Oscil(frequency, volume, Waves.SINE);
    oscil.patch(out);

    playing = true;
    fading = false;
  }

  // 一時停止
  public void pause() {
    playing = false;
    fading = true;
    prev_time = millis();
  }

  // 更新
  public void update() {
    int cur_time = millis();
    int time_diff = cur_time - prev_time;
    prev_time = cur_time;

    if (playing || !fading) return;

    // フェードアウト
    volume -= time_diff * fade_speed;

    if (volume <= 0) {
      volume = 0;
      fading = false;
      oscil.unpatch(out);
    }

    oscil.setAmplitude(volume);
  }
}
