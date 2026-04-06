document.addEventListener('DOMContentLoaded', () => {

  fetch('sidebar.html')
    .then(res => res.text())
    .then(html => {
      document.getElementById('sidebar').innerHTML = html;

      const currentPage = document.body.dataset.page;

      document.querySelectorAll('.sidebar-link').forEach(link => {
        if (link.dataset.page === currentPage) {
          link.classList.add('sidebar-item-active');
        }
      });
    });

  fetch('header.html')
    .then(res => res.text())
    .then(html => {
      document.body.insertAdjacentHTML('afterbegin', html);

      const headerHeight = document.getElementById('mainHeader').offsetHeight;
      document.body.style.paddingTop = headerHeight + 30 + 'px';

      // Set page title and description from body data attributes
      const title = document.body.dataset.title;
      const desc  = document.body.dataset.desc;

      const titleEl = document.getElementById('pageTitle');
      const descEl  = document.getElementById('pageDesc');

      if (titleEl && title) titleEl.textContent = title;
      if (descEl  && desc)  descEl.textContent  = desc;

      // Set icon based on page
      const iconMap = {
        dashboard:  'dashboard',
        students:   'school',
        donors:     'volunteer_activism',
        projects:   'folder_open',
        schools:    'account_balance',
        attendance: 'fact_check',
        devices:    'devices',
        hierarchy:  'account_tree',
        users:      'manage_accounts',
        roles:      'admin_panel_settings',
        logs:       'history',
      };
      const page = document.body.dataset.page;
      const iconEl = document.getElementById('pageIcon');
      if (iconEl && page && iconMap[page]) iconEl.textContent = iconMap[page];

      // Set today's date in header
      const dateEl = document.getElementById('headerDate');
      if (dateEl) {
        const today = new Date();
        const options = { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' };
        dateEl.textContent = today.toLocaleDateString('en-US', options);
      }
    });

  // Footer
  const footer = document.createElement('footer');
  footer.className = 'py-4 px-8 text-center text-xs text-slate-400 border-t border-slate-200';
  footer.innerHTML = 'Copyright &copy; 2026 Teach the World Foundation. All Rights Reserved.';
  const mainEl = document.querySelector('main');
  if (mainEl) mainEl.appendChild(footer);
});
