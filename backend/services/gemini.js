import { GoogleGenAI, Type } from '@google/genai';

const ai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY });

const challengeWordsSchema = {
    type: Type.ARRAY,
    items: { type: Type.STRING }
};

const feedbackItemSchema = {
    type: Type.OBJECT,
    properties: {
        score: { type: Type.NUMBER, description: 'Score from 1 to 100.' },
        feedback: { type: Type.STRING, description: '1-2 short, constructive bullet points with examples. Be critical but encouraging.' }
    },
    required: ['score', 'feedback']
};

const feedbackSchema = {
    type: Type.OBJECT,
    properties: {
        transcription: {
            type: Type.STRING,
            description: 'The verbatim transcription of the user\'s audio response.'
        },
        feedback: {
            type: Type.OBJECT,
            description: 'Detailed feedback on the user\'s speech.',
            properties: {
                grammar: feedbackItemSchema,
                pronunciation: feedbackItemSchema,
                fluency: feedbackItemSchema,
                vocabulary: { ...feedbackItemSchema, description: 'Evaluation of word choice, range, and idiomatic language use.' },
                clarity: { ...feedbackItemSchema, description: 'Evaluation of how clear and understandable the speech was.' },
                overallScore: {
                    type: Type.NUMBER,
                    description: 'A single, overall score from 1 to 100, averaging the other five scores.'
                },
                challengeWordsUsed: {
                    type: Type.ARRAY,
                    description: 'Evaluation of whether the user included the challenge words correctly.',
                    items: {
                        type: Type.OBJECT,
                        properties: {
                            word: { type: Type.STRING },
                            used: { type: Type.BOOLEAN },
                            feedback: { type: Type.STRING }
                        },
                        required: ['word', 'used', 'feedback']
                    }
                }
            },
            required: ['grammar', 'pronunciation', 'fluency', 'vocabulary', 'clarity', 'overallScore', 'challengeWordsUsed']
        }
    },
    required: ['transcription', 'feedback']
};

export async function getChallengeWords(prompt, targetLanguage, proficiency, weakSkills = [], reviewWords = []) {
    const weakSkillHint = weakSkills.length > 0
        ? `The user is weakest in: ${weakSkills.map(s => `${s.skill} (avg: ${Math.round(s.rolling_avg)})`).join(', ')}. Generate words that help practice these areas.`
        : '';

    const reviewHint = reviewWords.length > 0
        ? `Include some of these words the user needs to review: ${reviewWords.map(w => w.word).join(', ')}.`
        : '';

    const systemInstruction = `You are an AI language tutor. Based on the prompt and proficiency level for a ${targetLanguage} learner, generate a JSON array of 3-5 challenging but relevant vocabulary words the user should try to use. Adjust difficulty for the proficiency level. Return only the JSON array.
- Beginner: Common, useful words.
- Intermediate: More nuanced or less common words.
- Expert: Idiomatic expressions or highly specific vocabulary.
${weakSkillHint}
${reviewHint}`;

    const response = await ai.models.generateContent({
        model: 'gemini-2.5-flash',
        contents: `Prompt: "${prompt}", Proficiency: ${proficiency}`,
        config: {
            systemInstruction,
            responseMimeType: 'application/json',
            responseSchema: challengeWordsSchema,
        }
    });

    const jsonText = response.text.trim();
    if (!jsonText) throw new Error('API returned empty response for challenge words.');
    return JSON.parse(jsonText);
}

export async function evaluateSpeech(audioBase64, targetLanguage, proficiency, prompt, challengeWords) {
    const audioPart = {
        inlineData: {
            mimeType: 'audio/mp4',
            data: audioBase64,
        },
    };

    const systemInstruction = `You are an expert language coach for a user learning ${targetLanguage} at a ${proficiency} level. Your name is 'Lingo'.
Your task is to analyze the user's spoken response and provide a JSON object that strictly adheres to the provided schema.
1.  **Transcription**: Transcribe the audio verbatim.
2.  **Evaluation**: Evaluate the transcription on FIVE criteria: Grammar, Pronunciation, Fluency, Vocabulary, and Clarity.
    -   Provide a score from 1-100 for each. Be critical and accurate. A beginner might get 40-60, an expert 85-95. Don't give 100 easily.
    -   Provide 1-2 short, constructive bullet points for each.
3.  **Overall Score**: Calculate the average of the five scores.
4.  **Challenge Words**: Analyze the use of these words: [${challengeWords.join(', ')}]. For EACH word, specify if it was used and provide a brief comment on its contextual correctness.
Do NOT deviate from the JSON schema.`;

    const textPart = {
        text: `The user is a ${proficiency} learner responding to: "${prompt}". Challenge words: [${challengeWords.join(', ')}]. Analyze their response.`
    };

    const response = await ai.models.generateContent({
        model: 'gemini-2.5-flash',
        contents: { parts: [audioPart, textPart] },
        config: {
            systemInstruction,
            responseMimeType: 'application/json',
            responseSchema: feedbackSchema
        }
    });

    const jsonText = response.text?.trim();
    if (!jsonText) throw new Error('AI service returned an empty response. The audio may be too short or unclear.');

    let parsed;
    try {
        parsed = JSON.parse(jsonText);
    } catch {
        throw new Error('AI returned invalid JSON. Please try recording again.');
    }

    if (!parsed.transcription || !parsed.feedback) {
        console.error('Incomplete AI response:', JSON.stringify(parsed).slice(0, 500));
        throw new Error('AI could not fully analyze the audio. Please speak clearly for at least 5 seconds and try again.');
    }

    return parsed;
}
