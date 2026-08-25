// 48kHz to 16kHz, the one thing both recognisers need and neither provides.
//
// The microphone is captured at 48kHz because that is what the call's audio
// encoder wants, and every model here wants 16kHz, so something has to decimate.
// Asking the AudioContext for 16kHz instead would degrade the audio the far end
// receives, which is the opposite of the point.

const INPUT_SAMPLE_RATE = 48000;
const MODEL_SAMPLE_RATE = 16000;
const DECIMATION = INPUT_SAMPLE_RATE / MODEL_SAMPLE_RATE;

// Low pass ahead of the decimation. Without it every frequency above 8kHz folds
// back down into the speech band as noise the model has never heard in training,
// which costs more accuracy than the filter costs CPU.
const FILTER_CUTOFF_HZ = 7000;
const FILTER_TAPS = 47;

function lowPassCoefficients() {
    const coefficients = new Float32Array(FILTER_TAPS);
    const middle = (FILTER_TAPS - 1) / 2;
    const angular = 2 * Math.PI * (FILTER_CUTOFF_HZ / INPUT_SAMPLE_RATE);
    let total = 0;

    for (let i = 0; i < FILTER_TAPS; i++) {
        const offset = i - middle;
        const sinc = offset === 0 ? angular : Math.sin(angular * offset) / offset;
        // Hamming, which puts the first sidelobe far enough down that the fold
        // back is inaudible against a microphone's own noise floor.
        const window = 0.54 - 0.46 * Math.cos((2 * Math.PI * i) / (FILTER_TAPS - 1));
        coefficients[i] = sinc * window;
        total += coefficients[i];
    }

    for (let i = 0; i < FILTER_TAPS; i++) coefficients[i] /= total;
    return coefficients;
}

class Downsampler {
    constructor() {
        this.coefficients = lowPassCoefficients();
        // Input samples the filter has not finished with, carried into the next
        // block so output stays exactly one sample in three across boundaries.
        // Dropping them would put a discontinuity at every block boundary, which
        // the model hears as a click every 20ms.
        this.pending = new Float32Array(0);
    }

    process(input) {
        const buffer = new Float32Array(this.pending.length + input.length);
        buffer.set(this.pending, 0);
        buffer.set(input, this.pending.length);

        const count = Math.max(0, Math.ceil((buffer.length - FILTER_TAPS + 1) / DECIMATION));
        const output = new Float32Array(count);
        for (let i = 0; i < count; i++) {
            let sum = 0;
            for (let tap = 0; tap < FILTER_TAPS; tap++) sum += this.coefficients[tap] * buffer[i * DECIMATION + tap];
            output[i] = sum;
        }

        this.pending = buffer.slice(count * DECIMATION);
        return output;
    }
}
