import ddf.minim.*;
import ddf.minim.ugens.*;

public class Note {
  private Oscil oscil;
  private ADSR adsr;
  private boolean playing = false;

  public Note(float frequency, float volume, float fade_time, AudioOutput out) {
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

  // 一時停止
  public void pause() {
    if (playing) {
      playing = false;
      adsr.noteOff();
    }
  }
}
