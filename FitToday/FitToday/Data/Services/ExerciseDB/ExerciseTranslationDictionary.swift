//
//  ExerciseTranslationDictionary.swift
//  FitToday
//
//  Created by AI on 16/01/26.
//

import Foundation

/// 💡 Learn: Dicionário centralizado de traduções PT→EN para exercícios
/// Reutilizado por ExerciseMediaResolver e ExerciseNameNormalizer
///
/// IMPORTANTE: Manter sincronizado com exercícios do LibraryWorkoutsSeed.json
/// Este dicionário é usado para normalizar nomes de exercícios antes de fazer
/// matching com a API ExerciseDB que está em inglês.
enum ExerciseTranslationDictionary {

    /// Tradução de nomes de exercícios do português para inglês
    /// Usado para melhorar a busca na API ExerciseDB
    static let portugueseToEnglish: [String: String] = [
        // ✅ TRÍCEPS - Crítico para assertividade
        "extensão de tríceps com halter": "dumbbell triceps extension",
        "extensão de tríceps": "triceps extension",
        "extensão de tríceps overhead com halter": "dumbbell triceps extension",
        "tríceps testa": "lying triceps extension",
        "tríceps francês": "dumbbell triceps extension",
        "tríceps pulley": "triceps pushdown",
        "tríceps corda": "cable rope triceps pushdown",
        "triceps pushdown": "triceps pushdown",
        "triceps extension": "triceps extension",
        "dumbbell triceps extension": "dumbbell triceps extension",

        // ✅ BÍCEPS
        "rosca direta": "barbell curl",
        "rosca alternada": "dumbbell alternate bicep curl",
        "rosca martelo": "hammer curl",
        "rosca concentrada": "concentration curl",
        "rosca scott": "ez barbell preacher curl",
        "rosca com halter": "dumbbell curl",
        "bíceps": "bicep curl",
        "biceps curl": "bicep curl",
        "rosca": "curl",
        "curl": "curl",

        // ✅ PEITO
        "supino reto com barra": "barbell bench press",
        "supino reto": "barbell bench press",
        "supino inclinado com halteres": "incline dumbbell press",
        "supino inclinado": "incline dumbbell press",
        "supino declinado": "decline barbell bench press",
        "supino com halteres": "dumbbell bench press",
        "supino": "bench press",
        "bench press": "bench press",
        "crucifixo": "dumbbell fly",
        "voadora": "pec deck fly",
        "voadora na máquina": "pec deck fly",
        "crossover": "cable crossover",
        "flexão": "push-up",
        "push-up": "push-up",
        "pushup": "push-up",
        "flexão de braço": "push-up",
        "flexão diamante": "diamond push-up",
        "diamond push-up": "diamond push-up",
        "flexão com aplauso": "clap push-up",
        "flexão archer": "archer push-up",
        "flexão pike": "pike push-up",

        // ✅ COSTAS
        "puxada frontal": "lat pulldown",
        "puxada": "lat pulldown",
        "pulldown": "lat pulldown",
        "remada curvada": "bent over barbell row",
        "remada curvada com barra": "bent over barbell row",
        "remada baixa": "cable seated row",
        "remada unilateral com halter": "dumbbell bent over row",
        "remada unilateral": "dumbbell bent over row",
        "remada cavalinho": "t-bar row",
        "remada serrote": "dumbbell bent over row",
        "remada": "row",
        "row": "row",
        "barra": "pull-up",
        "pull-up": "pull-up",
        "pullup": "pull-up",
        "barra fixa": "pull-up",
        "bent over row": "bent over barbell row",
        "one arm dumbbell row": "dumbbell bent over row",
        "t-bar row": "t-bar row",

        // ✅ OMBROS
        "desenvolvimento com halteres": "dumbbell shoulder press",
        "desenvolvimento militar": "barbell shoulder press",
        "desenvolvimento": "shoulder press",
        "shoulder press": "shoulder press",
        "elevação lateral": "dumbbell lateral raise",
        "elevação lateral com halter": "dumbbell lateral raise",
        "lateral raise": "dumbbell lateral raise",
        "elevação frontal": "dumbbell front raise",
        "crucifixo invertido": "reverse fly",
        "face pull": "face pull",

        // ✅ PERNAS
        "agachamento livre": "barbell squat",
        "agachamento": "squat",
        "squat": "squat",
        "agachamento com salto": "jump squat",
        "jump squat": "jump squat",
        "agachamento búlgaro": "dumbbell single leg split squat",
        "bulgarian split squat": "dumbbell single leg split squat",
        "agachamento sumô": "sumo squat",
        "sumo squat": "sumo squat",
        "agachamento frontal": "barbell front squat",
        "front squat": "barbell front squat",
        "leg press": "leg press",
        "leg press 45": "sled 45 leg press",
        "extensão de pernas": "leg extension",
        "extensão de perna": "leg extension",
        "cadeira extensora": "leg extension",
        "mesa flexora": "lying leg curl",
        "flexão de perna": "lying leg curl",
        "afundo": "dumbbell lunge",
        "lunge": "dumbbell lunge",
        "passada": "dumbbell lunge",
        "stiff": "barbell stiff legged deadlift",
        "levantamento terra": "barbell deadlift",
        "deadlift": "barbell deadlift",
        "elevação de panturrilha": "standing calf raise",
        "panturrilha em pé": "standing calf raise",
        "panturrilha sentado": "seated calf raise",

        // ✅ GLÚTEOS
        "elevação pélvica": "glute bridge",
        "glute bridge": "glute bridge",
        "hip thrust": "barbell hip thrust",
        "ponte": "glute bridge",
        "elevação pélvica com halter": "dumbbell hip thrust",
        "abdução de quadril": "hip abduction machine",
        "kickback": "cable kickback",

        // ✅ CORE/ABDOMINAIS
        "abdominal tradicional": "crunch",
        "abdominal": "crunch",
        "crunch": "crunch",
        "abdominal infra": "reverse crunch",
        "abdominal reverso": "reverse crunch",
        "reverse crunch": "reverse crunch",
        "abdominal bicicleta": "bicycle crunch",
        "bicycle crunch": "bicycle crunch",
        "abdominal canivete": "v-up",
        "v-up": "v-up",
        "abdominal oblíquo": "oblique crunch",
        "side crunch": "oblique crunch",
        "prancha": "plank",
        "plank": "plank",
        "prancha lateral": "side plank",
        "side plank": "side plank",
        "prancha com elevação de braço": "plank arm raise",
        "prancha com rotação": "plank rotation",
        "prancha lateral com rotação": "side plank rotation",
        "prancha alta": "push-up position plank",
        "prancha baixa": "forearm plank",
        "dead bug": "dead bug",
        "bird dog": "bird dog",
        "elevação de joelhos": "knee raise",
        "knee raise": "knee raise",
        "elevação de joelhos suspenso": "hanging knee raise",
        "hanging knee raise": "hanging knee raise",
        "elevação de pernas": "leg raise",
        "leg raise": "leg raise",

        // ✅ CARDIO & FULL BODY
        "burpee": "burpee",
        "burpee com salto": "burpee",
        "burpee com flexão": "burpee",
        "mountain climber": "mountain climber",
        "escalador": "mountain climber",
        "jumping jack": "jumping jack",
        "polichinelo": "jumping jack",
        "high knees": "high knee skips",
        "corrida no lugar": "high knee skips",
    ]
}
