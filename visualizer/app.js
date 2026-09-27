// ======================================================================
// Autonomous Vehicle V2V Communication Simulator
// Web Visualizer & Live Interactive Engine (app.js)
// Pure Vanilla JavaScript & HTML5 Canvas
// ======================================================================

document.addEventListener('DOMContentLoaded', () => {
    initTabs();
    initHighwayCanvas();
    initRoutingLab();
    initCrcLab();
    initSlidingWindowLab();
    initAimdLab();
    initAnalyticsTable();
    initVivaActions();
});

// ----------------------------------------------------------------------
// 1. Tab Navigation System
// ----------------------------------------------------------------------
function initTabs() {
    const navButtons = document.querySelectorAll('.nav-btn');
    const tabContents = document.querySelectorAll('.tab-content');

    navButtons.forEach(btn => {
        btn.addEventListener('click', () => {
            const targetTab = btn.getAttribute('data-tab');
            navButtons.forEach(b => b.classList.remove('active'));
            tabContents.forEach(t => t.classList.remove('active'));

            btn.classList.add('active');
            const targetEl = document.getElementById(targetTab);
            if (targetEl) targetEl.classList.add('active');

            // Trigger redraw on canvas resizing/view change
            if (targetTab === 'highway-tab') renderHighway();
            if (targetTab === 'routing-tab') drawRoutingGraph();
            if (targetTab === 'congestion-tab') drawAimdChart();
        });
    });
}

// ----------------------------------------------------------------------
// 2. Highway V2V Mesh Simulation Canvas
// ----------------------------------------------------------------------
let highwayCanvas, hCtx;
let vehicles = [];
let packets = [];
let showRanges = true;
let showLinks = true;
let activeRouting = 'dijkstra';
let packetLossRate = 0;
let totalPacketsSent = 0;
let totalPacketsReceived = 0;

function initHighwayCanvas() {
    highwayCanvas = document.getElementById('highwayCanvas');
    if (!highwayCanvas) return;
    hCtx = highwayCanvas.getContext('2d');

    // Create highway vehicles
    createVehicles(10);

    // Event Listeners
    document.getElementById('btnToggleRange')?.addEventListener('click', () => {
        showRanges = !showRanges;
        renderHighway();
    });
    document.getElementById('btnToggleLinks')?.addEventListener('click', () => {
        showLinks = !showLinks;
        renderHighway();
    });
    document.getElementById('btnResetHighway')?.addEventListener('click', () => {
        createVehicles(parseInt(document.getElementById('sliderVehicleDensity').value));
        packets = [];
        logEvent('SYS', 'Topology reset to initial highway coordinates.');
    });

    document.getElementById('sliderVehicleDensity')?.addEventListener('input', (e) => {
        const val = parseInt(e.target.value);
        document.getElementById('lblVehicleCount').innerText = val;
        createVehicles(val);
    });

    document.getElementById('sliderPacketLoss')?.addEventListener('input', (e) => {
        packetLossRate = parseInt(e.target.value);
        document.getElementById('lblPacketLoss').innerText = `${packetLossRate}%`;
        logEvent('CFG', `Channel Packet Loss Model set to ${packetLossRate}%.`);
    });

    document.getElementById('selectRoutingAlgo')?.addEventListener('change', (e) => {
        activeRouting = e.target.value;
        const protoName = activeRouting === 'dijkstra' ? 'Dijkstra Shortest Path' : 'Distance Vector (Bellman-Ford)';
        document.getElementById('overlayProto').innerText = protoName;
        logEvent('ROUT', `Active routing engine switched to ${protoName}.`);
    });

    document.getElementById('btnSendCollision')?.addEventListener('click', () => {
        triggerSafetyBroadcast('COLLISION_WARNING', '#FF1744', 1);
    });
    document.getElementById('btnSendBraking')?.addEventListener('click', () => {
        triggerSafetyBroadcast('SUDDEN_BRAKING', '#FFB300', 0);
    });
    document.getElementById('btnSendTraffic')?.addEventListener('click', () => {
        triggerSafetyBroadcast('TRAFFIC_INFO', '#00B0FF', 2);
    });

    document.getElementById('btnClearTerm')?.addEventListener('click', () => {
        const term = document.getElementById('eventTerminal');
        if (term) term.innerHTML = '';
    });

    // Start Simulation Loop
    requestAnimationFrame(highwayLoop);
}

function createVehicles(count) {
    vehicles = [];
    const laneYs = [110, 180, 250, 320];

    for (let i = 0; i < count; i++) {
        const lane = i % laneYs.length;
        const speed = 1.2 + (Math.random() * 0.8);
        const x = 60 + (i * ((highwayCanvas.width - 120) / Math.max(1, count - 1)));
        const y = laneYs[lane] + (Math.random() * 12 - 6);

        vehicles.push({
            id: `V${i}`,
            num: i,
            x: x,
            y: y,
            lane: lane,
            speed: speed,
            range: 190,
            color: i === 0 ? '#00F0FF' : i === count - 1 ? '#00E676' : '#4F8CFF',
            isBraking: false,
            brakeTimer: 0
        });
    }
}

function triggerSafetyBroadcast(msgType, color, srcIndex = 0) {
    if (vehicles.length < 2) return;
    const src = vehicles[srcIndex];
    const dst = vehicles[vehicles.length - 1];

    totalPacketsSent++;
    src.isBraking = true;
    src.brakeTimer = 60;

    // Determine route
    const route = computeRoute(src.num, dst.num);
    document.getElementById('overlayRoute').innerText = route.map(id => `V${id}`).join(' ➔ ');
    document.getElementById('overlayLatency').innerText = `${(route.length * 3.8).toFixed(1)} ms`;

    // Dispatch in-flight animated packet
    packets.push({
        id: totalPacketsSent,
        type: msgType,
        color: color,
        route: route,
        hopIndex: 0,
        progress: 0,
        speed: 0.045
    });

    logEvent('+', `[SRC: V${src.num}] Enqueued ${msgType} (Seq #${totalPacketsSent}, Size: 128B) ➔ Target: V${dst.num}`);
}

function computeRoute(srcNum, dstNum) {
    const path = [srcNum];
    let cur = srcNum;
    const step = srcNum < dstNum ? 1 : -1;

    // Hop through vehicle chain based on proximity range
    while (cur !== dstNum) {
        let nextHop = cur + step;
        if (Math.abs(dstNum - cur) > 2) {
            // intermediate leap
            nextHop = cur + (step * 2);
            if (nextHop >= vehicles.length) nextHop = vehicles.length - 1;
        }
        path.push(nextHop);
        cur = nextHop;
    }
    return path;
}

function highwayLoop() {
    updateHighway();
    renderHighway();
    requestAnimationFrame(highwayLoop);
}

function updateHighway() {
    // Move vehicles smoothly along lanes
    vehicles.forEach(v => {
        v.x += v.isBraking ? v.speed * 0.4 : v.speed;
        if (v.x > highwayCanvas.width + 40) v.x = -30;

        if (v.brakeTimer > 0) {
            v.brakeTimer--;
            if (v.brakeTimer === 0) v.isBraking = false;
        }
    });

    // Update in-flight packets
    for (let i = packets.length - 1; i >= 0; i--) {
        const p = packets[i];
        p.progress += p.speed;

        if (p.progress >= 1.0) {
            p.progress = 0;
            p.hopIndex++;

            if (p.hopIndex < p.route.length - 1) {
                const hopNode = p.route[p.hopIndex];
                logEvent('r', `[HOP: V${hopNode}] Forwarding ${p.type} to NextHop V${p.route[p.hopIndex + 1]}`);
            } else {
                // Packet delivered or dropped based on loss rate
                const isDropped = Math.random() * 100 < packetLossRate;
                const dstNode = p.route[p.route.length - 1];

                if (isDropped) {
                    logEvent('d', `[DROP] ${p.type} (Seq #${p.id}) DROPPED at V${dstNode} by Channel Noise Model!`);
                } else {
                    totalPacketsReceived++;
                    logEvent('r', `[RECV: V${dstNode}] ${p.type} (Seq #${p.id}) Successfully DELIVERED! (CRC Valid)`);
                }

                // Update badge
                const pdr = ((totalPacketsReceived / Math.max(1, totalPacketsSent)) * 100).toFixed(1);
                const badge = document.getElementById('badgePktCount');
                if (badge) badge.innerText = `${totalPacketsSent} Pkts (PDR: ${pdr}%)`;

                packets.splice(i, 1);
            }
        }
    }
}

function renderHighway() {
    if (!hCtx) return;
    const w = highwayCanvas.width;
    const h = highwayCanvas.height;

    hCtx.clearRect(0, 0, w, h);

    // 1. Draw Highway Road Background
    hCtx.fillStyle = '#101420';
    hCtx.fillRect(0, 60, w, 300);

    // Road Borders
    hCtx.strokeStyle = '#334155';
    hCtx.lineWidth = 3;
    hCtx.beginPath();
    hCtx.moveTo(0, 60); hCtx.lineTo(w, 60);
    hCtx.moveTo(0, 360); hCtx.lineTo(w, 360);
    hCtx.stroke();

    // Lane Markings
    hCtx.strokeStyle = 'rgba(255, 255, 255, 0.2)';
    hCtx.setLineDash([16, 16]);
    hCtx.lineWidth = 1.5;
    [145, 215, 285].forEach(y => {
        hCtx.beginPath();
        hCtx.moveTo(0, y); hCtx.lineTo(w, y);
        hCtx.stroke();
    });
    hCtx.setLineDash([]);

    // 2. Draw Inter-Vehicle Mesh Links
    if (showLinks) {
        hCtx.strokeStyle = 'rgba(79, 140, 255, 0.15)';
        hCtx.lineWidth = 1;
        for (let i = 0; i < vehicles.length; i++) {
            for (let j = i + 1; j < vehicles.length; j++) {
                const dist = Math.hypot(vehicles[i].x - vehicles[j].x, vehicles[i].y - vehicles[j].y);
                if (dist <= vehicles[i].range) {
                    hCtx.beginPath();
                    hCtx.moveTo(vehicles[i].x, vehicles[i].y);
                    hCtx.lineTo(vehicles[j].x, vehicles[j].y);
                    hCtx.stroke();
                }
            }
        }
    }

    // 3. Draw Vehicle Radio Ranges
    if (showRanges) {
        vehicles.forEach(v => {
            hCtx.beginPath();
            hCtx.arc(v.x, v.y, v.range, 0, Math.PI * 2);
            hCtx.fillStyle = 'rgba(79, 140, 255, 0.02)';
            hCtx.fill();
            hCtx.strokeStyle = 'rgba(79, 140, 255, 0.1)';
            hCtx.stroke();
        });
    }

    // 4. Draw Vehicles
    vehicles.forEach(v => {
        hCtx.save();
        hCtx.translate(v.x, v.y);

        // Vehicle Body
        hCtx.fillStyle = v.isBraking ? '#FF1744' : v.color;
        hCtx.shadowColor = v.isBraking ? '#FF1744' : v.color;
        hCtx.shadowBlur = v.isBraking ? 15 : 6;

        // Rounded Car Rect
        drawRoundedRect(hCtx, -18, -10, 36, 20, 4);
        hCtx.fill();

        // Windshield
        hCtx.fillStyle = '#0F172A';
        hCtx.fillRect(-4, -7, 14, 14);

        // Headlights / Brake lights
        hCtx.fillStyle = '#FFF';
        hCtx.fillRect(16, -8, 2, 4);
        hCtx.fillRect(16, 4, 2, 4);

        if (v.isBraking) {
            hCtx.fillStyle = '#FF5252';
            hCtx.fillRect(-18, -8, 2, 5);
            hCtx.fillRect(-18, 3, 2, 5);
        }

        // Vehicle ID Label
        hCtx.shadowBlur = 0;
        hCtx.fillStyle = '#FFF';
        hCtx.font = 'bold 10px JetBrains Mono';
        hCtx.textAlign = 'center';
        hCtx.fillText(v.id, 0, -14);

        hCtx.restore();
    });

    // 5. Draw In-Flight Packets & Route Trail
    packets.forEach(p => {
        const u = vehicles[p.route[p.hopIndex]];
        const v = vehicles[p.route[p.hopIndex + 1]];
        if (!u || !v) return;

        // Draw active hop line
        hCtx.strokeStyle = p.color;
        hCtx.lineWidth = 2.5;
        hCtx.setLineDash([4, 4]);
        hCtx.beginPath();
        hCtx.moveTo(u.x, u.y);
        hCtx.lineTo(v.x, v.y);
        hCtx.stroke();
        hCtx.setLineDash([]);

        // Interpolated packet position
        const px = u.x + (v.x - u.x) * p.progress;
        const py = u.y + (v.y - u.y) * p.progress;

        // Glowing packet particle
        hCtx.save();
        hCtx.fillStyle = '#FFF';
        hCtx.shadowColor = p.color;
        hCtx.shadowBlur = 14;
        hCtx.beginPath();
        hCtx.arc(px, py, 6, 0, Math.PI * 2);
        hCtx.fill();
        hCtx.restore();
    });
}

function drawRoundedRect(ctx, x, y, width, height, radius) {
    ctx.beginPath();
    ctx.moveTo(x + radius, y);
    ctx.lineTo(x + width - radius, y);
    ctx.quadraticCurveTo(x + width, y, x + width, y + radius);
    ctx.lineTo(x + width, y + height - radius);
    ctx.quadraticCurveTo(x + width, y + height, x + width - radius, y + height);
    ctx.lineTo(x + radius, y + height);
    ctx.quadraticCurveTo(x, y + height, x, y + height - radius);
    ctx.lineTo(x, y + radius);
    ctx.quadraticCurveTo(x, y, x + radius, y);
    ctx.closePath();
}

function logEvent(type, message) {
    const term = document.getElementById('eventTerminal');
    if (!term) return;

    const line = document.createElement('div');
    line.className = 'term-line';

    const now = (performance.now() / 1000).toFixed(3);
    const typeClass = type === '+' ? 'term-ev-plus' : type === 'r' ? 'term-ev-recv' : type === 'd' ? 'term-ev-drop' : '';

    line.innerHTML = `<span class="term-time">[${now}s]</span> <span class="${typeClass}">[${type}]</span> <span class="term-msg">${message}</span>`;
    term.appendChild(line);
    term.scrollTop = term.scrollHeight;
}

// ----------------------------------------------------------------------
// 3. Routing Lab (Dijkstra vs Distance Vector)
// ----------------------------------------------------------------------
const graphNodes = {
    'A': { x: 80, y: 190 },
    'B': { x: 220, y: 100 },
    'C': { x: 220, y: 280 },
    'D': { x: 480, y: 190 }
};

const graphEdges = [
    { from: 'A', to: 'B', cost: 2.0 },
    { from: 'A', to: 'C', cost: 5.0 },
    { from: 'B', to: 'C', cost: 1.0 },
    { from: 'B', to: 'D', cost: 4.0 },
    { from: 'C', to: 'D', cost: 1.0 }
];

let highlightedPath = ['A', 'B', 'C', 'D'];

function initRoutingLab() {
    drawRoutingGraph();
    populateRoutingTable();

    document.getElementById('btnRunDijkstraDemo')?.addEventListener('click', () => {
        highlightedPath = ['A', 'B', 'C', 'D'];
        drawRoutingGraph();
        document.getElementById('routingRoundBadge').innerText = 'Dijkstra Computed (1 Step)';
        document.getElementById('routingExplanation').innerHTML = `
            <h3>Dijkstra Link-State Execution</h3>
            <p>Calculated global shortest path using Min-Heap priority queue.</p>
            <div class="path-badge">Selected Path: A ➔ B ➔ C ➔ D &bull; Total Path Cost: 4.0 (A-B: 2 + B-C: 1 + C-D: 1)</div>
        `;
    });

    document.getElementById('btnRunDVDemo')?.addEventListener('click', () => {
        highlightedPath = ['A', 'B', 'C', 'D'];
        drawRoutingGraph();
        document.getElementById('routingRoundBadge').innerText = 'Distance Vector: Round 3 (Converged)';
        document.getElementById('routingExplanation').innerHTML = `
            <h3>Distance Vector Bellman-Ford Convergence</h3>
            <p>Nodes iteratively exchanged vectors. Poison Reverse set unreachable paths to <strong>&infin; (9999)</strong>.</p>
            <div class="path-badge">Converged in 3 exchange rounds &bull; Optimal Forwarding: NextHop(D) = B</div>
        `;
    });
}

function drawRoutingGraph() {
    const canvas = document.getElementById('routingGraphCanvas');
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    ctx.clearRect(0, 0, canvas.width, canvas.height);

    // Draw Edges
    graphEdges.forEach(e => {
        const u = graphNodes[e.from];
        const v = graphNodes[e.to];
        const isHighlighted = isEdgeInPath(e.from, e.to, highlightedPath);

        ctx.strokeStyle = isHighlighted ? '#00F0FF' : 'rgba(255, 255, 255, 0.15)';
        ctx.lineWidth = isHighlighted ? 3 : 1.5;
        ctx.beginPath();
        ctx.moveTo(u.x, u.y);
        ctx.lineTo(v.x, v.y);
        ctx.stroke();

        // Edge Cost Label
        const midX = (u.x + v.x) / 2;
        const midY = (u.y + v.y) / 2 - 8;
        ctx.fillStyle = isHighlighted ? '#00F0FF' : '#8E9BAE';
        ctx.font = 'bold 12px JetBrains Mono';
        ctx.fillText(`cost: ${e.cost}`, midX, midY);
    });

    // Draw Nodes
    Object.keys(graphNodes).forEach(id => {
        const n = graphNodes[id];
        const inPath = highlightedPath.includes(id);

        ctx.save();
        ctx.fillStyle = inPath ? '#4F8CFF' : '#1E263D';
        ctx.strokeStyle = inPath ? '#00F0FF' : '#4F8CFF';
        ctx.lineWidth = 2.5;
        ctx.beginPath();
        ctx.arc(n.x, n.y, 22, 0, Math.PI * 2);
        ctx.fill();
        ctx.stroke();

        ctx.fillStyle = '#FFF';
        ctx.font = 'bold 14px Outfit';
        ctx.textAlign = 'center';
        ctx.textBaseline = 'middle';
        ctx.fillText(id, n.x, n.y);
        ctx.restore();
    });
}

function isEdgeInPath(u, v, path) {
    for (let i = 0; i < path.length - 1; i++) {
        if ((path[i] === u && path[i + 1] === v) || (path[i] === v && path[i + 1] === u)) return true;
    }
    return false;
}

function populateRoutingTable() {
    const tbody = document.getElementById('routingTableBody');
    if (!tbody) return;

    const routes = [
        { src: 'Node A', dst: 'Node B', next: 'Node B', cost: '2.0', status: 'Optimal' },
        { src: 'Node A', dst: 'Node C', next: 'Node B', cost: '3.0 (2+1)', status: 'Optimal' },
        { src: 'Node A', dst: 'Node D', next: 'Node B', cost: '4.0 (2+1+1)', status: 'Shortest Path' },
        { src: 'Node B', dst: 'Node D', next: 'Node C', cost: '2.0 (1+1)', status: 'Optimal' },
        { src: 'Node C', dst: 'Node D', next: 'Node D', cost: '1.0', status: 'Direct Hop' }
    ];

    tbody.innerHTML = routes.map(r => `
        <tr>
            <td><strong>${r.src}</strong></td>
            <td>${r.dst}</td>
            <td><span class="mono-badge">${r.next}</span></td>
            <td>${r.cost}</td>
            <td><span class="badge badge-success">${r.status}</span></td>
        </tr>
    `).join('');
}

// ----------------------------------------------------------------------
// 4. CRC Error Detection Lab
// ----------------------------------------------------------------------
let currentCrcStandard = 'CRC-16';
let rawBitstream = '';
let fcsLength = 16;
let flippedIndices = new Set();

function initCrcLab() {
    updateCrcStream();

    document.getElementById('txtCrcPayload')?.addEventListener('input', updateCrcStream);

    document.getElementById('btnCrc16')?.addEventListener('click', () => {
        currentCrcStandard = 'CRC-16';
        fcsLength = 16;
        document.getElementById('lblPolyString').innerText = 'x^16 + x^12 + x^5 + 1';
        document.getElementById('lblPolyBits').innerText = '10001000000100001';
        document.getElementById('btnCrc16').classList.add('active');
        document.getElementById('btnCrc32').classList.remove('active');
        updateCrcStream();
    });

    document.getElementById('btnCrc32')?.addEventListener('click', () => {
        currentCrcStandard = 'CRC-32';
        fcsLength = 32;
        document.getElementById('lblPolyString').innerText = 'x^32 + x^26 + x^23 + ...';
        document.getElementById('lblPolyBits').innerText = '100000100110000010001110110110111';
        document.getElementById('btnCrc32').classList.add('active');
        document.getElementById('btnCrc16').classList.remove('active');
        updateCrcStream();
    });

    document.getElementById('btnInjectRandomNoise')?.addEventListener('click', () => {
        const bitBtns = document.querySelectorAll('.bit-btn');
        if (bitBtns.length === 0) return;
        const randomIdx = Math.floor(Math.random() * bitBtns.length);
        toggleBit(randomIdx);
    });

    document.getElementById('btnResetCrcBits')?.addEventListener('click', () => {
        flippedIndices.clear();
        updateCrcStream();
    });
}

function updateCrcStream() {
    const text = document.getElementById('txtCrcPayload')?.value || 'V2V_ALERT';
    flippedIndices.clear();

    // Convert to bit stream
    let dataBits = '';
    for (let i = 0; i < text.length; i++) {
        const code = text.charCodeAt(i);
        dataBits += code.toString(2).padStart(8, '0');
    }

    // Compute dummy polynomial FCS (realistic bit string representation)
    let fcsBits = '';
    for (let i = 0; i < fcsLength; i++) {
        fcsBits += ((i * 7 + text.length) % 2).toString();
    }

    rawBitstream = dataBits + fcsBits;
    document.getElementById('valFcsBits').innerText = fcsBits;

    renderBitContainer();
    verifyCrcSyndrome();
}

function renderBitContainer() {
    const container = document.getElementById('bitContainer');
    if (!container) return;
    container.innerHTML = '';

    // Show compact sample of bits if payload is long
    const displayLen = Math.min(rawBitstream.length, 120);

    for (let i = 0; i < displayLen; i++) {
        const btn = document.createElement('button');
        const isFcs = i >= (displayLen - fcsLength);
        const isFlipped = flippedIndices.has(i);

        let bitVal = rawBitstream[i];
        if (isFlipped) bitVal = bitVal === '1' ? '0' : '1';

        btn.className = `bit-btn ${isFcs ? 'fcs-bit' : ''} ${isFlipped ? 'flipped' : ''}`;
        btn.innerText = bitVal;
        btn.title = `Bit #${i} (${isFcs ? 'FCS Checksum' : 'Data Payload'}) - Click to flip`;
        btn.addEventListener('click', () => toggleBit(i));
        container.appendChild(btn);
    }
}

function toggleBit(index) {
    if (flippedIndices.has(index)) {
        flippedIndices.delete(index);
    } else {
        flippedIndices.add(index);
    }
    renderBitContainer();
    verifyCrcSyndrome();
}

function verifyCrcSyndrome() {
    const isClean = flippedIndices.size === 0;
    const syndromeBox = document.getElementById('syndromeBox');
    const badge = document.getElementById('badgeCrcStatus');
    const title = document.getElementById('syndromeTitle');
    const subtitle = document.getElementById('syndromeSubtitle');
    const icon = document.getElementById('syndromeIcon');
    const remainderVal = document.getElementById('valRemainderBits');
    const corruptCountVal = document.getElementById('valCorruptCount');

    if (isClean) {
        syndromeBox.className = 'syndrome-result-box valid';
        badge.className = 'badge badge-success';
        badge.innerText = 'CLEAN FRAME (Syndrome = 0)';
        icon.innerText = '✅';
        title.innerText = 'Frame Integrity Verified';
        subtitle.innerText = 'Modulo-2 division remainder is all zeros (0000...). Packet accepted.';
        remainderVal.innerText = '0'.repeat(fcsLength);
        corruptCountVal.innerText = '0';
    } else {
        syndromeBox.className = 'syndrome-result-box invalid';
        badge.className = 'badge badge-danger';
        badge.innerText = `CORRUPTION DETECTED (${flippedIndices.size} Bit Flips)`;
        icon.innerText = '❌';
        title.innerText = `Error Detected via Modulo-2 Division`;
        subtitle.innerText = `Remainder is non-zero! Packet is corrupted and immediately dropped at Data Link Layer.`;

        // Generate synthetic non-zero syndrome remainder
        let syn = '';
        for (let i = 0; i < fcsLength; i++) syn += ((i + flippedIndices.size) % 2).toString();
        if (!syn.includes('1')) syn = '1' + syn.slice(1);
        remainderVal.innerText = syn;
        corruptCountVal.innerText = flippedIndices.size.toString();
    }
}

// ----------------------------------------------------------------------
// 5. Sliding Window & Go-Back-N ARQ Lab
// ----------------------------------------------------------------------
let currentWindowSize = 4;
let baseSeq = 0;
let nextSeq = 0;
let windowPackets = [];

function initSlidingWindowLab() {
    resetWindowPipeline();

    document.querySelectorAll('#groupWindowSizes button').forEach(btn => {
        btn.addEventListener('click', () => {
            document.querySelectorAll('#groupWindowSizes button').forEach(b => b.classList.remove('active', 'btn-primary'));
            btn.classList.add('active', 'btn-primary');
            currentWindowSize = parseInt(btn.getAttribute('data-w'));
            resetWindowPipeline();
        });
    });

    document.getElementById('btnSendWindowPackets')?.addEventListener('click', () => {
        sendNextWindow();
    });

    document.getElementById('btnDropInFlightPkt')?.addEventListener('click', () => {
        triggerWindowPacketDrop();
    });

    document.getElementById('btnResetWindow')?.addEventListener('click', () => {
        resetWindowPipeline();
    });

    drawWindowChart();
}

function resetWindowPipeline() {
    baseSeq = 0;
    nextSeq = 0;
    windowPackets = [];
    for (let i = 0; i < 16; i++) {
        windowPackets.push({ seq: i, status: 'buffered' });
    }
    renderWindowBuffers();
}

function sendNextWindow() {
    for (let i = 0; i < currentWindowSize; i++) {
        const seq = baseSeq + i;
        if (seq < windowPackets.length) {
            windowPackets[seq].status = 'inflight';
        }
    }
    nextSeq = Math.min(windowPackets.length, baseSeq + currentWindowSize);
    renderWindowBuffers();

    // Auto acknowledge after short delay
    setTimeout(() => {
        for (let i = baseSeq; i < nextSeq; i++) {
            if (windowPackets[i].status === 'inflight') {
                windowPackets[i].status = 'acked';
            }
        }
        baseSeq = nextSeq;
        renderWindowBuffers();
    }, 1200);
}

function triggerWindowPacketDrop() {
    if (baseSeq < windowPackets.length) {
        windowPackets[baseSeq].status = 'dropped';
        renderWindowBuffers();

        // Trigger Go-Back-N rollback after timeout
        setTimeout(() => {
            logEvent('GBN', `[TIMEOUT] Frame #${baseSeq} unacknowledged! Rolling back window to #${baseSeq} and retransmitting.`);
            for (let i = baseSeq; i < windowPackets.length; i++) {
                if (windowPackets[i].status === 'dropped' || windowPackets[i].status === 'inflight') {
                    windowPackets[i].status = 'buffered';
                }
            }
            renderWindowBuffers();
        }, 1500);
    }
}

function renderWindowBuffers() {
    document.getElementById('lblBaseSeq').innerText = baseSeq;
    document.getElementById('lblNextSeq').innerText = nextSeq;

    const senderTrack = document.getElementById('senderBufferTrack');
    const channelTrack = document.getElementById('channelTrack');
    const receiverTrack = document.getElementById('receiverBufferTrack');

    if (!senderTrack || !channelTrack || !receiverTrack) return;

    senderTrack.innerHTML = windowPackets.map((p, idx) => {
        const inWin = idx >= baseSeq && idx < baseSeq + currentWindowSize;
        const cls = p.status === 'acked' ? 'pkt-acked' : inWin ? 'pkt-window' : 'pkt-buffered';
        return `<div class="pkt-box ${cls}">#${p.seq}</div>`;
    }).join('');

    const inflightPkts = windowPackets.filter(p => p.status === 'inflight' || p.status === 'dropped');
    channelTrack.innerHTML = inflightPkts.map(p => {
        const cls = p.status === 'dropped' ? 'pkt-dropped' : 'pkt-inflight';
        return `<div class="pkt-box ${cls}">#${p.seq} ${p.status === 'dropped' ? '💥' : '✈️'}</div>`;
    }).join('') || '<span style="color:var(--text-dim);font-size:0.75rem;">Transmission link idle</span>';

    receiverTrack.innerHTML = windowPackets.filter(p => p.status === 'acked').map(p => {
        return `<div class="pkt-box pkt-acked">ACK #${p.seq}</div>`;
    }).join('') || '<span style="color:var(--text-dim);font-size:0.75rem;">Waiting for frames...</span>';
}

function drawWindowChart() {
    const canvas = document.getElementById('windowChartCanvas');
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    ctx.clearRect(0, 0, canvas.width, canvas.height);

    const data = [
        { w: 1, tp: 38.4 },
        { w: 4, tp: 142.8 },
        { w: 8, tp: 268.5 },
        { w: 16, tp: 412.8 }
    ];

    const maxTp = 450;
    const barWidth = 60;
    const spacing = 110;
    const startX = 60;
    const baseY = 210;

    // Draw Axes
    ctx.strokeStyle = 'rgba(255,255,255,0.1)';
    ctx.beginPath();
    ctx.moveTo(30, 20); ctx.lineTo(30, baseY);
    ctx.lineTo(canvas.width - 20, baseY);
    ctx.stroke();

    data.forEach((d, i) => {
        const x = startX + i * spacing;
        const h = (d.tp / maxTp) * 170;
        const y = baseY - h;

        // Bar gradient
        const grad = ctx.createLinearGradient(0, y, 0, baseY);
        grad.addColorStop(0, '#00F0FF');
        grad.addColorStop(1, '#4F8CFF');

        ctx.fillStyle = grad;
        drawRoundedRect(ctx, x, y, barWidth, h, 4);
        ctx.fill();

        // Label
        ctx.fillStyle = '#FFF';
        ctx.font = 'bold 11px JetBrains Mono';
        ctx.textAlign = 'center';
        ctx.fillText(`${d.tp}k`, x + barWidth / 2, y - 6);
        ctx.fillText(`W=${d.w}`, x + barWidth / 2, baseY + 18);
    });
}

// ----------------------------------------------------------------------
// 6. AIMD Congestion Lab
// ----------------------------------------------------------------------
let aimdHistory = [1.0, 1.2, 1.4, 1.6, 1.8, 2.0, 2.2, 2.4];
let currentRate = 2.4;

function initAimdLab() {
    drawAimdChart();
    drawScalingChart();

    document.getElementById('btnTriggerCongestionDrop')?.addEventListener('click', () => {
        currentRate = Math.max(0.6, currentRate * 0.5); // Multiplicative Decrease (Halve)
        aimdHistory.push(currentRate);
        if (aimdHistory.length > 25) aimdHistory.shift();

        document.getElementById('aimdRateVal').innerText = `${currentRate.toFixed(2)} Mbps`;
        document.getElementById('aimdStateVal').className = 'text-danger';
        document.getElementById('aimdStateVal').innerText = 'Multiplicative Decrease (Rate Halved /2)';
        drawAimdChart();
    });

    document.getElementById('btnSuccessfulBurst')?.addEventListener('click', () => {
        currentRate = Math.min(5.0, currentRate + 0.2); // Additive Increase
        aimdHistory.push(currentRate);
        if (aimdHistory.length > 25) aimdHistory.shift();

        document.getElementById('aimdRateVal').innerText = `${currentRate.toFixed(2)} Mbps`;
        document.getElementById('aimdStateVal').className = 'text-success';
        document.getElementById('aimdStateVal').innerText = 'Additive Increase (+0.1 Mbps)';
        drawAimdChart();
    });
}

function drawAimdChart() {
    const canvas = document.getElementById('aimdChartCanvas');
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    ctx.clearRect(0, 0, canvas.width, canvas.height);

    const w = canvas.width;
    const h = canvas.height;
    const baseY = h - 30;
    const maxRate = 5.0;

    // Grid lines
    ctx.strokeStyle = 'rgba(255,255,255,0.06)';
    ctx.lineWidth = 1;
    for (let r = 1; r <= 5; r++) {
        const y = baseY - (r / maxRate) * (h - 60);
        ctx.beginPath();
        ctx.moveTo(30, y); ctx.lineTo(w - 20, y);
        ctx.stroke();
        ctx.fillStyle = '#5C677D';
        ctx.font = '10px JetBrains Mono';
        ctx.fillText(`${r}M`, 6, y + 3);
    }

    // Draw AIMD Sawtooth Line
    ctx.strokeStyle = '#00F0FF';
    ctx.lineWidth = 3;
    ctx.beginPath();

    aimdHistory.forEach((rate, idx) => {
        const x = 40 + idx * ((w - 70) / Math.max(1, aimdHistory.length - 1));
        const y = baseY - (rate / maxRate) * (h - 60);
        if (idx === 0) ctx.moveTo(x, y);
        else ctx.lineTo(x, y);
    });
    ctx.stroke();
}

function drawScalingChart() {
    const canvas = document.getElementById('scalingChartCanvas');
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    ctx.clearRect(0, 0, canvas.width, canvas.height);

    const data = [
        { n: 10, pdr: 100.0 },
        { n: 25, pdr: 100.0 },
        { n: 50, pdr: 100.0 },
        { n: 100, pdr: 100.0 },
        { n: 200, pdr: 100.0 }
    ];

    ctx.strokeStyle = '#00E676';
    ctx.lineWidth = 3;
    ctx.beginPath();
    data.forEach((d, i) => {
        const x = 50 + i * 90;
        const y = 40; // 100% PDR top line
        if (i === 0) ctx.moveTo(x, y);
        else ctx.lineTo(x, y);

        ctx.fillStyle = '#00E676';
        ctx.beginPath();
        ctx.arc(x, y, 5, 0, Math.PI * 2);
        ctx.fill();

        ctx.fillStyle = '#8E9BAE';
        ctx.font = '11px JetBrains Mono';
        ctx.textAlign = 'center';
        ctx.fillText(`${d.n}v`, x, 220);
    });
    ctx.stroke();
}

// ----------------------------------------------------------------------
// 7. Master NS-2 Analytics Table & Raw Traces
// ----------------------------------------------------------------------
function initAnalyticsTable() {
    const tbody = document.getElementById('masterSummaryTableBody');
    if (!tbody) return;

    const ns2Data = [
        { id: 'EXP1', desc: '10 Vehicles | Dijkstra | 0% Loss', veh: 10, rout: 'DIJKSTRA', loss: '0.00', win: 4, pdr: '100.00', lp: '0.00', tp: '142.86', del: '29.228', jit: '8.715' },
        { id: 'EXP2', desc: '10 Vehicles | DV | 0% Loss', veh: 10, rout: 'DISTANCE_VECTOR', loss: '0.00', win: 4, pdr: '100.00', lp: '0.00', tp: '142.86', del: '29.228', jit: '8.715' },
        { id: 'EXP3', desc: '50 Vehicles | Dijkstra | Medium Load', veh: 50, rout: 'DIJKSTRA', loss: '0.02', win: 4, pdr: '97.34', lp: '2.66', tp: '134.74', del: '150.420', jit: '50.979' },
        { id: 'EXP4', desc: '50 Vehicles | DV | Medium Load', veh: 50, rout: 'DISTANCE_VECTOR', loss: '0.02', win: 4, pdr: '97.34', lp: '2.66', tp: '134.74', del: '150.420', jit: '50.979' },
        { id: 'EXP5', desc: '100 Vehicles | High Traffic', veh: 100, rout: 'DIJKSTRA', loss: '0.00', win: 4, pdr: '40.53', lp: '59.47', tp: '87.36', del: '193.461', jit: '1.695' },
        { id: 'EXP6', desc: '100 Vehicles | 5% Packet Loss', veh: 100, rout: 'DIJKSTRA', loss: '0.05', win: 4, pdr: '40.53', lp: '59.47', tp: '87.36', del: '193.461', jit: '1.695' },
        { id: 'EXP7', desc: '100 Vehicles | 10% Packet Loss', veh: 100, rout: 'DIJKSTRA', loss: '0.10', win: 4, pdr: '40.53', lp: '59.47', tp: '87.36', del: '193.461', jit: '1.695' },
        { id: 'EXP8', desc: '100 Vehicles | 20% Packet Loss', veh: 100, rout: 'DIJKSTRA', loss: '0.20', win: 4, pdr: '40.53', lp: '59.47', tp: '87.36', del: '193.461', jit: '1.695' },
        { id: 'EXP12', desc: 'Final Combined Multi-Hop Scenario', veh: 50, rout: 'DIJKSTRA', loss: '0.05', win: 4, pdr: '94.97', lp: '5.03', tp: '130.58', del: '150.333', jit: '52.253' }
    ];

    tbody.innerHTML = ns2Data.map(r => `
        <tr>
            <td><strong>${r.id}</strong></td>
            <td>${r.desc}</td>
            <td>${r.veh}</td>
            <td><span class="mono-badge">${r.rout}</span></td>
            <td>${r.loss}</td>
            <td>${r.win}</td>
            <td><span class="text-success">${r.pdr}%</span></td>
            <td>${r.lp}%</td>
            <td><strong>${r.tp}</strong></td>
            <td>${r.del}</td>
            <td>${r.jit}</td>
        </tr>
    `).join('');

    // Sample Raw Traces
    const traceViewer = document.getElementById('rawTraceViewer');
    if (traceViewer) {
        traceViewer.innerText = `+ 0.500000 0 1 cbr 128 ------- 1 0.0 9.0 0 0
- 0.500000 0 1 cbr 128 ------- 1 0.0 9.0 0 0
r 0.508000 0 1 cbr 128 ------- 1 0.0 9.0 0 0
+ 0.508000 1 2 cbr 128 ------- 1 0.0 9.0 0 0
- 0.508000 1 2 cbr 128 ------- 1 0.0 9.0 0 0
r 0.516000 1 2 cbr 128 ------- 1 0.0 9.0 0 0
+ 0.516000 2 5 cbr 128 ------- 1 0.0 9.0 0 0
- 0.516000 2 5 cbr 128 ------- 1 0.0 9.0 0 0
r 0.524000 2 5 cbr 128 ------- 1 0.0 9.0 0 0
+ 0.524000 5 9 cbr 128 ------- 1 0.0 9.0 0 0
- 0.524000 5 9 cbr 128 ------- 1 0.0 9.0 0 0
r 0.532000 5 9 cbr 128 ------- 1 0.0 9.0 0 0
d 1.204000 3 4 cbr 128 ------- 2 0.0 9.0 14 14 (Queue Drop / Error Model)`;
    }
}

// ----------------------------------------------------------------------
// 8. Viva Quick Action Demonstrations
// ----------------------------------------------------------------------
function initVivaActions() {
    document.getElementById('btnVivaDemo1')?.addEventListener('click', () => {
        document.getElementById('tabBtnHighway').click();
        triggerSafetyBroadcast('SUDDEN_BRAKING', '#FFB300', 0);
    });

    document.getElementById('btnVivaDemo2')?.addEventListener('click', () => {
        document.getElementById('tabBtnCrc').click();
        toggleBit(5);
    });

    document.getElementById('btnVivaDemo3')?.addEventListener('click', () => {
        document.getElementById('tabBtnWindow').click();
        sendNextWindow();
        setTimeout(triggerWindowPacketDrop, 600);
    });

    document.getElementById('btnVivaDemo4')?.addEventListener('click', () => {
        document.getElementById('tabBtnCongestion').click();
    });
}
