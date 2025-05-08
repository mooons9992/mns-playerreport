// Main NUI Callback Handler
window.addEventListener('message', function(event) {
    const data = event.data;
    
    switch(data.action) {
        case 'openReportMenu':
            showReportMenu();
            break;
        case 'openAdminMenu':
            showAdminMenu(data.reports);
            break;
        case 'updateReports':
            updateReportsList(data.reports);
            break;
        case 'showNotification':
            showAdminNotification(data.reportId, data.playerName, data.message);
            break;
        case 'updateCooldown':
            updateCooldown(data.time);
            break;
        case 'closeAll':
            closeAllMenus();
            break;
        case 'showPlayerInfo':
            showPlayerInfo(data.playerInfo);
            break;
    }
});

// Player Report Menu Functions
function showReportMenu() {
    document.getElementById('reportModal').style.display = 'flex';
    document.getElementById('reportMessage').focus();
    
    // Check if cooldown is active
    const cooldownElement = document.getElementById('cooldownTimer');
    if (cooldownElement.classList.contains('hidden')) {
        document.getElementById('submitReport').disabled = false;
    } else {
        document.getElementById('submitReport').disabled = true;
    }
}

function closeReportMenu() {
    document.getElementById('reportModal').style.display = 'none';
    document.getElementById('reportMessage').value = '';
    document.getElementById('charCount').textContent = '0';
}

// Admin Reports Menu Functions
function showAdminMenu(reports) {
    document.getElementById('adminModal').style.display = 'flex';
    
    if (reports) {
        updateReportsList(reports);
    } else {
        // If no reports data provided, request them from the server
        fetch(`https://${GetParentResourceName()}/getAllReports`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({})
        });
    }
}

function closeAdminMenu() {
    document.getElementById('adminModal').style.display = 'none';
}

function updateReportsList(reports) {
    const reportsListElement = document.getElementById('reportsList');
    reportsListElement.innerHTML = '';
    
    // Get active filter
    const activeFilter = document.querySelector('.filter-btn.active')?.id || 'filterAllReports';
    
    let activeReports = 0;
    let filteredReports = [];
    
    // Process and filter reports
    for (const reportId in reports) {
        const report = reports[reportId];
        
        // Convert old status names to new ones
        if (report.status === 'open') report.status = 'pending';
        if (report.status === 'closed') report.status = 'resolved';
        
        // Apply filter
        if (activeFilter === 'filterAllReports' || 
            (activeFilter === 'filterPendingReports' && report.status === 'pending') ||
            (activeFilter === 'filterInProgressReports' && report.status === 'inProgress') ||
            (activeFilter === 'filterResolvedReports' && report.status === 'resolved')) {
            filteredReports.push(report);
        }
    }
    
    // Sort reports by timestamp descending (newest first)
    filteredReports.sort((a, b) => b.timestamp - a.timestamp);
    
    // Display reports
    for (const report of filteredReports) {
        activeReports++;
        
        const reportElement = document.createElement('div');
        reportElement.className = `report-item report-${report.status}`;
        reportElement.dataset.id = report.id;
        
        // Get status label from status
        const statusLabel = getStatusLabel(report.status);
        const statusClass = `status-${report.status.replace('Progress', '-progress')}`;
        
        // Format timestamp
        const reportDate = new Date(report.timestamp * 1000);
        const formattedTime = reportDate.toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'});
        const formattedDate = reportDate.toLocaleDateString();
        
        reportElement.innerHTML = `
            <div class="report-info">
                <div class="report-id">#${report.id} - ${report.playerName} <span class="${statusClass}">(${statusLabel})</span></div>
                <div class="report-time">${formattedDate} at ${formattedTime}</div>
                <div class="report-player">${report.charinfo ? `${report.charinfo.firstname} ${report.charinfo.lastname}` : 'Unknown Character'}</div>
                <div class="report-message">${report.message}</div>
            </div>
            <div class="report-buttons">
                ${report.status === 'pending' ? `<button class="btn btn-info teleport-btn" data-id="${report.id}"><i class="fas fa-location-arrow"></i> Teleport</button>` : ''}
                ${report.status === 'pending' || report.status === 'inProgress' ? `<button class="btn btn-success resolve-btn" data-id="${report.id}"><i class="fas fa-check"></i> Resolve</button>` : ''}
                <button class="btn btn-primary details-btn" data-id="${report.id}"><i class="fas fa-search"></i> Details</button>
            </div>
        `;
        
        reportsListElement.appendChild(reportElement);
    }
    
    if (activeReports === 0) {
        reportsListElement.innerHTML = '<div class="no-reports">No matching reports</div>';
    }
    
    // Add event listeners to new buttons
    document.querySelectorAll('.teleport-btn').forEach(button => {
        button.addEventListener('click', function() {
            const reportId = this.getAttribute('data-id');
            teleportToPlayer(reportId);
        });
    });
    
    document.querySelectorAll('.resolve-btn').forEach(button => {
        button.addEventListener('click', function() {
            const reportId = this.getAttribute('data-id');
            closeReport(reportId);
        });
    });
    
    document.querySelectorAll('.details-btn').forEach(button => {
        button.addEventListener('click', function() {
            const reportId = this.getAttribute('data-id');
            showReportDetails(reportId, reports[reportId]);
        });
    });
}

// Helper function to get status label
function getStatusLabel(status) {
    switch(status) {
        case 'pending': return 'Pending';
        case 'inProgress': return 'In Progress';
        case 'resolved': return 'Resolved';
        default: return status;
    }
}

// Report Details Functions
function showReportDetails(reportId, report) {
    if (!report) return;
    
    document.getElementById('detailsReportId').textContent = `#${reportId}`;
    document.getElementById('detailsPlayerName').textContent = report.playerName || 'Unknown';
    document.getElementById('detailsPlayerId').textContent = report.player || 'Unknown';
    
    // Display character info if available
    if (report.charinfo) {
        document.getElementById('detailsCharInfo').textContent = 
            `${report.charinfo.firstname} ${report.charinfo.lastname} (${report.charinfo.gender === 0 ? 'Male' : 'Female'}, ${report.charinfo.birthdate})`;
    } else {
        document.getElementById('detailsCharInfo').textContent = 'No character info available';
    }
    
    // Set status with appropriate color class
    const statusElement = document.getElementById('detailsStatus');
    statusElement.textContent = getStatusLabel(report.status);
    statusElement.className = 'detail-value status-' + report.status.replace('Progress', '-progress');
    
    // Format and set timestamp
    if (report.timestamp) {
        const date = new Date(report.timestamp * 1000);
        document.getElementById('detailsTimestamp').textContent = date.toLocaleString();
    } else {
        document.getElementById('detailsTimestamp').textContent = 'Unknown';
    }
    
    // Set report message
    document.getElementById('detailsMessage').textContent = report.message || 'No message provided';
    
    // Configure buttons
    const teleportBtn = document.getElementById('detailsTeleport');
    const closeReportBtn = document.getElementById('detailsCloseReport');
    
    teleportBtn.dataset.id = reportId;
    closeReportBtn.dataset.id = reportId;
    
    // Show/hide teleport button based on report status
    teleportBtn.style.display = report.status === 'pending' ? 'block' : 'none';
    
    // Update close button text based on status
    if (report.status === 'resolved') {
        closeReportBtn.innerHTML = '<i class="fas fa-check-circle"></i> Already Resolved';
        closeReportBtn.disabled = true;
    } else {
        closeReportBtn.innerHTML = '<i class="fas fa-check"></i> Mark as Resolved';
        closeReportBtn.disabled = false;
    }
    
    // Show the modal
    document.getElementById('reportDetailsModal').style.display = 'flex';
}

function closeReportDetails() {
    document.getElementById('reportDetailsModal').style.display = 'none';
}

// Admin Notification Functions
function showAdminNotification(reportId, playerName, message) {
    const notification = document.getElementById('adminNotification');
    
    // Set notification content
    document.getElementById('notificationReportId').textContent = `#${reportId}`;
    document.getElementById('notificationPlayerName').textContent = playerName;
    document.getElementById('notificationMessage').textContent = message;
    
    // Set button data attributes
    document.getElementById('notificationTeleport').setAttribute('data-id', reportId);
    document.getElementById('notificationViewDetails').setAttribute('data-id', reportId);
    document.getElementById('notificationClose').setAttribute('data-id', reportId);
    
    // Show notification
    notification.classList.remove('hidden');
    notification.classList.add('fadeIn');
    
    // Auto-hide after 30 seconds
    setTimeout(() => {
        if (!notification.classList.contains('hidden')) {
            notification.classList.add('hidden');
        }
    }, 30000);
    
    // Play notification sound
    playNotificationSound();
}

function closeAdminNotification() {
    document.getElementById('adminNotification').classList.add('hidden');
}

// Show player information
function showPlayerInfo(playerInfo) {
    if (!playerInfo) return;
    
    // In a future update, this function would populate a player info modal
    console.log('Received player info:', playerInfo);
}

// Utility Functions
function updateCooldown(seconds) {
    const cooldownElement = document.getElementById('cooldownTimer');
    const timeElement = document.getElementById('cooldownTime');
    
    if (seconds > 0) {
        const minutes = Math.floor(seconds / 60);
        const remainingSeconds = seconds % 60;
        timeElement.textContent = `${minutes.toString().padStart(2, '0')}:${remainingSeconds.toString().padStart(2, '0')}`;
        
        cooldownElement.classList.remove('hidden');
        document.getElementById('submitReport').disabled = true;
    } else {
        cooldownElement.classList.add('hidden');
        document.getElementById('submitReport').disabled = false;
    }
}

function closeAllMenus() {
    closeReportMenu();
    closeAdminMenu();
    closeAdminNotification();
    closeReportDetails();
}

function playNotificationSound() {
    const audio = document.getElementById('notificationSound');
    audio.volume = 0.5;
    audio.play().catch(error => console.error('Error playing notification sound:', error));
}

function applyFilter(filterId) {
    // Remove active class from all filter buttons
    document.querySelectorAll('.filter-btn').forEach(btn => {
        btn.classList.remove('active');
    });
    
    // Add active class to the clicked filter button
    document.getElementById(filterId).classList.add('active');
    
    // Get reports and re-apply the filter
    fetch(`https://${GetParentResourceName()}/getAllReports`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({})
    });
}

// Report Actions
function submitReport() {
    const message = document.getElementById('reportMessage').value.trim();
    
    if (message.length < 3) {
        // Show error
        document.getElementById('reportMessage').style.borderColor = 'var(--danger-color)';
        setTimeout(() => {
            document.getElementById('reportMessage').style.borderColor = '';
        }, 2000);
        return;
    }
    
    // Send report to server
    fetch(`https://${GetParentResourceName()}/submitReport`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            message: message
        })
    });
    
    closeReportMenu();
}

function teleportToPlayer(reportId) {
    fetch(`https://${GetParentResourceName()}/teleportToPlayer`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            reportId: reportId
        })
    });
    
    // Don't close the admin menu here, server action will update UI
    closeAdminNotification();
    closeReportDetails();
}

function closeReport(reportId) {
    fetch(`https://${GetParentResourceName()}/closeReport`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            reportId: reportId
        })
    });
    
    // We don't close menus here to allow viewing other reports
    closeAdminNotification();
    closeReportDetails();
}

function getPlayerInfo(reportId) {
    fetch(`https://${GetParentResourceName()}/getPlayerInfo`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            reportId: reportId
        })
    });
}

// Event Listeners
document.addEventListener('DOMContentLoaded', function() {
    // Character counter
    document.getElementById('reportMessage').addEventListener('input', function() {
        const length = this.value.length;
        document.getElementById('charCount').textContent = length;
    });
    
    // Report menu buttons
    document.getElementById('submitReport').addEventListener('click', submitReport);
    document.getElementById('cancelReport').addEventListener('click', closeReportMenu);
    document.getElementById('reportModal').querySelector('.close').addEventListener('click', closeReportMenu);
    
    // Admin menu buttons
    document.getElementById('refreshReports').addEventListener('click', function() {
        fetch(`https://${GetParentResourceName()}/getAllReports`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({})
        });
    });
    document.getElementById('closeAdminModal').addEventListener('click', closeAdminMenu);
    document.getElementById('adminModal').querySelector('.close').addEventListener('click', closeAdminMenu);
    
    // Filter buttons
    document.getElementById('filterAllReports').addEventListener('click', function() {
        applyFilter('filterAllReports');
    });
    document.getElementById('filterPendingReports').addEventListener('click', function() {
        applyFilter('filterPendingReports');
    });
    document.getElementById('filterInProgressReports').addEventListener('click', function() {
        applyFilter('filterInProgressReports');
    });
    document.getElementById('filterResolvedReports').addEventListener('click', function() {
        applyFilter('filterResolvedReports');
    });
    
    // Notification buttons
    document.getElementById('notificationTeleport').addEventListener('click', function() {
        const reportId = this.getAttribute('data-id');
        teleportToPlayer(reportId);
    });
    
    document.getElementById('notificationViewDetails').addEventListener('click', function() {
        const reportId = this.getAttribute('data-id');
        
        // Get reports first to ensure we have the latest data
        fetch(`https://${GetParentResourceName()}/getAllReports`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                onSuccess: {
                    action: 'showDetailsForReport',
                    reportId: reportId
                }
            })
        });
        
        closeAdminNotification();
    });
    
    document.getElementById('notificationClose').addEventListener('click', function() {
        const reportId = this.getAttribute('data-id');
        closeReport(reportId);
    });
    
    document.querySelector('.notification-close').addEventListener('click', closeAdminNotification);
    
    // Report details buttons
    document.getElementById('detailsTeleport').addEventListener('click', function() {
        const reportId = this.getAttribute('data-id');
        teleportToPlayer(reportId);
    });
    
    document.getElementById('detailsCloseReport').addEventListener('click', function() {
        const reportId = this.getAttribute('data-id');
        closeReport(reportId);
    });
    
    document.getElementById('reportDetailsModal').querySelector('.close').addEventListener('click', closeReportDetails);
    
    // Close menus on ESC key
    document.addEventListener('keydown', function(event) {
        if (event.key === 'Escape') {
            closeAllMenus();
            
            // Notify the resource that we're closing the UI
            fetch(`https://${GetParentResourceName()}/escapePressed`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({})
            });
        }
    });
});

// Function to expose UI to FiveM resource
function postNUIMessage(data) {
    window.dispatchEvent(new MessageEvent('message', {
        data: data
    }));
}