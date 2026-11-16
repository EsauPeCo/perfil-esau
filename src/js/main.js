/**
 * Perfil de Esaú Pérez: comportamiento de la página.
 *
 * 1. Filtro del índice de proyectos (Todos, Web, Móvil, Juegos).
 * 2. Resalta en la navegación la sección que se está leyendo.
 * 3. Escribe el año actual en el pie de página.
 *
 * Sin JavaScript la página funciona igual: el filtro permanece oculto
 * y la tabla muestra todos los proyectos.
 */
(function () {
  'use strict';

  const NOMBRES = { todos: 'todos los proyectos', web: 'proyectos web', movil: 'proyectos móviles', juegos: 'proyectos de videojuegos' };

  function iniciarFiltro() {
    const grupo = document.querySelector('.filter');
    const filas = Array.from(document.querySelectorAll('.index tbody tr'));
    const estado = document.querySelector('.projects__count');
    if (!grupo || filas.length === 0) return;

    const botones = Array.from(grupo.querySelectorAll('.filter__btn'));

    function aplicar(categoria) {
      let visibles = 0;
      filas.forEach(function (fila) {
        const coincide = categoria === 'todos' || fila.dataset.cat === categoria;
        fila.hidden = !coincide;
        if (coincide) visibles += 1;
      });
      botones.forEach(function (boton) {
        boton.setAttribute('aria-pressed', String(boton.dataset.filter === categoria));
      });
      if (estado) {
        estado.textContent = 'Mostrando ' + visibles + ' de ' + filas.length + ': ' + NOMBRES[categoria] + '.';
      }
    }

    grupo.addEventListener('click', function (evento) {
      const boton = evento.target.closest('.filter__btn');
      if (boton) aplicar(boton.dataset.filter);
    });

    grupo.hidden = false;
    aplicar('todos');
  }

  function iniciarNavegacionActiva() {
    const enlaces = Array.from(document.querySelectorAll('.nav__links a[href^="#"]'));
    if (!('IntersectionObserver' in window) || enlaces.length === 0) return;

    const porId = new Map();
    enlaces.forEach(function (enlace) {
      const seccion = document.querySelector(enlace.getAttribute('href'));
      if (seccion) porId.set(seccion.id, enlace);
    });

    const observador = new IntersectionObserver(function (entradas) {
      entradas.forEach(function (entrada) {
        const enlace = porId.get(entrada.target.id);
        if (!enlace) return;
        if (entrada.isIntersecting) {
          enlaces.forEach(function (otro) { otro.removeAttribute('aria-current'); });
          enlace.setAttribute('aria-current', 'true');
        }
      });
    }, { rootMargin: '-40% 0px -55% 0px' });

    porId.forEach(function (_enlace, id) { observador.observe(document.getElementById(id)); });
  }

  function escribirAnio() {
    document.querySelectorAll('[data-year]').forEach(function (nodo) {
      nodo.textContent = String(new Date().getFullYear());
    });
  }

  document.addEventListener('DOMContentLoaded', function () {
    iniciarFiltro();
    iniciarNavegacionActiva();
    escribirAnio();
  });
})();
