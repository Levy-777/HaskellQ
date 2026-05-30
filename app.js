// Variáveis de Estado
let currentPhaseIdx = 0;
let simulationTimeout = null;
let isPlaying = false;

// Elementos da UI
const gridEl = document.getElementById('grid');
const policyGridEl = document.getElementById('policy-grid');
const phaseTitleEl = document.getElementById('phase-title');
const statusTextEl = document.getElementById('status-text');
const btnPlay = document.getElementById('btn-play');
const btnReset = document.getElementById('btn-reset');
const tabBtns = document.querySelectorAll('.tab-btn');

// Agent Element
const agentEl = document.createElement('div');
agentEl.classList.add('agent');

// Mapeamento de Símbolos
const ARROW_MAP = {
  'GoUp': '↑',
  'GoDown': '↓',
  'GoLeft': '←',
  'GoRight': '→'
};

const CELL_CLASS_MAP = {
  'Start': 'start',
  'Frozen': 'frozen',
  'Hole': 'hole',
  'Goal': 'goal'
};

function init() {
  if (typeof simData === 'undefined') {
    phaseTitleEl.innerText = 'Erro: data.js não encontrado. Rode o Haskell primeiro!';
    return;
  }
  
  // Renderiza Grids Estáticos
  renderGrid(simData.grid, gridEl);
  gridEl.appendChild(agentEl); // Adiciona agente ao grid
  
  // Configura Eventos
  tabBtns.forEach(btn => {
    btn.addEventListener('click', (e) => {
      const idx = parseInt(e.target.getAttribute('data-phase'));
      selectPhase(idx);
    });
  });

  btnPlay.addEventListener('click', togglePlay);
  btnReset.addEventListener('click', resetSimulation);

  // Seleciona Fase Inicial
  selectPhase(0);
}

function renderGrid(gridData, container) {
  container.innerHTML = '';
  gridData.forEach((row, r) => {
    row.forEach((cell, c) => {
      const div = document.createElement('div');
      div.classList.add('cell');
      div.classList.add(CELL_CLASS_MAP[cell] || 'frozen');
      if (cell === 'Start') div.innerText = 'S';
      if (cell === 'Goal') div.innerText = 'G';
      container.appendChild(div);
    });
  });
}

function renderPolicy(policyData, gridData) {
  policyGridEl.innerHTML = '';
  policyData.forEach((row, r) => {
    row.forEach((action, c) => {
      const div = document.createElement('div');
      div.classList.add('cell');
      const cellType = gridData[r][c];
      
      if (cellType === 'Hole' || cellType === 'Goal') {
        div.classList.add(CELL_CLASS_MAP[cellType]);
        if (cellType === 'Goal') div.innerText = 'G';
      } else {
        const span = document.createElement('span');
        span.classList.add('arrow');
        span.innerText = ARROW_MAP[action] || '';
        div.appendChild(span);
      }
      policyGridEl.appendChild(div);
    });
  });
}

function selectPhase(idx) {
  // Parar simulação atual
  stopSimulation();
  
  // Atualizar abas
  tabBtns.forEach(btn => btn.classList.remove('active'));
  tabBtns[idx].classList.add('active');
  
  currentPhaseIdx = idx;
  const phaseData = simData.phases[idx];
  
  phaseTitleEl.innerText = phaseData.name;
  renderPolicy(phaseData.policy, simData.grid);
  resetSimulation();
}

// Lógica de Movimentação do Agente
function moveAgentTo(r, c) {
  const cellSize = 80;
  const gap = 8;
  const offset = (cellSize - (cellSize * 0.7)) / 2; // Centraliza o agente
  
  const x = c * (cellSize + gap) + offset;
  const y = r * (cellSize + gap) + offset;
  
  agentEl.style.transform = `translate(${x}px, ${y}px)`;
}

function resetSimulation() {
  stopSimulation();
  moveAgentTo(0, 0); // Posição Start
  statusTextEl.innerText = 'Aguardando simulação...';
  statusTextEl.style.color = 'var(--accent)';
}

function togglePlay() {
  if (isPlaying) {
    stopSimulation();
  } else {
    startSimulation();
  }
}

function stopSimulation() {
  isPlaying = false;
  btnPlay.innerText = '▶ Simular';
  clearTimeout(simulationTimeout);
}

function startSimulation() {
  isPlaying = true;
  btnPlay.innerText = '⏸ Pausar';
  
  const steps = simData.phases[currentPhaseIdx].simulation;
  let stepIdx = 0;
  
  // Reseta para 0,0 antes de começar se estivermos no fim
  moveAgentTo(0, 0);

  function nextStep() {
    if (!isPlaying) return;
    
    if (stepIdx >= steps.length) {
      // Fim da simulação
      stopSimulation();
      // O agente estourou o limite de passos mas não morreu nem venceu (Fase 2)
      statusTextEl.innerText = 'Simulação finalizada (Estourou limite de passos).';
      statusTextEl.style.color = 'var(--text-muted)';
      return;
    }

    const step = steps[stepIdx];
    
    // Calcula para onde ele vai baseado na ação atual (com limites de parede)
    let nextR = step.pos[0];
    let nextC = step.pos[1];
    if (step.action === 'GoUp') nextR = Math.max(0, nextR - 1);
    if (step.action === 'GoDown') nextR = Math.min(3, nextR + 1);
    if (step.action === 'GoLeft') nextC = Math.max(0, nextC - 1);
    if (step.action === 'GoRight') nextC = Math.min(3, nextC + 1);

    // Mover visualmente
    moveAgentTo(nextR, nextC);
    
    let statusMsg = `Passo ${stepIdx + 1}: Mover ${ARROW_MAP[step.action]}`;
    statusTextEl.style.color = 'var(--accent)';

    if (step.done) {
      if (step.reward > 0) {
        statusMsg = '🎉 OBJETIVO ALCANÇADO!';
        statusTextEl.style.color = 'var(--goal)';
      } else {
        statusMsg = '💀 CAIU NO BURACO!';
        statusTextEl.style.color = 'red';
      }
      statusTextEl.innerText = statusMsg;
      stopSimulation();
      return;
    }

    statusTextEl.innerText = statusMsg;
    stepIdx++;
    simulationTimeout = setTimeout(nextStep, 500); // 500ms por passo
  }

  // Espera um pouquinho antes do primeiro passo
  simulationTimeout = setTimeout(nextStep, 500);
}

// Inicia a aplicação
document.addEventListener('DOMContentLoaded', init);
