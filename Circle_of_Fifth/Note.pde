import ddf.minim.*;
import ddf.minim.ugens.*;

// 音
public class Note {
  private Oscil oscil;
  private ADSR adsr;
  AudioOutput out;
  private boolean playing = false;

  public Note(float frequency, float volume, float fade_time, AudioOutput out) {
    this.out = out;
    this.oscil = new Oscil(frequency, volume, Waves.SINE);
    this.adsr = new ADSR(volume, 0.01, 0, 1, fade_time);
    oscil.patch(adsr);
    adsr.patch(out);
  }

  // 再生
  public void play() {
    if (!playing) {
      playing = true;
      oscil.reset();
      adsr.noteOn();
    }
  }

  // 停止
  public void stop() {
    if (playing) {
      playing = false;
      adsr.noteOff();
    }
  }
  
  // 解放
  public void free() {
    adsr.unpatchAfterRelease(out);
  }
}
