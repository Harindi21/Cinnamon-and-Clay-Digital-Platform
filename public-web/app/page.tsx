import Image from 'next/image';
import { connection } from 'next/server';

import { Gallery } from '@/components/gallery';
import { SiteNav } from '@/components/site-nav';
import { formatMoney, getMenu } from '@/lib/catalog';
import { withDemoMediaFallback } from '@/lib/demo-media';
import {
  getPublicMedia,
  mediaSrc,
  objectPosition
} from '@/lib/media';
import { getPublicReviews } from '@/lib/reviews';
import {
  getContact,
  getSiteContent,
  whatsappHref
} from '@/lib/site';

export default async function Home() {
  await connection();

  const [menu, content, contact, media, reviewData] = await Promise.all([
    getMenu(),
    getSiteContent(),
    getContact(),
    getPublicMedia(),
    getPublicReviews()
  ]);

  const displayMedia = withDemoMediaFallback(media);
  const whatsAppUrl = whatsappHref(contact.whatsapp);

  return (
    <main id="top">
      <SiteNav brand={content.brand.name} />

      <section className="hero" aria-labelledby="hero-title">
        {displayMedia.hero && (
          <Image
            className="heroMedia"
            src={mediaSrc(displayMedia.hero)}
            alt={displayMedia.hero.alt}
            fill
            priority
            sizes="100vw"
            style={{ objectPosition: objectPosition(displayMedia.hero) }}
          />
        )}

        <div className="shell heroContent">
          <p className="kicker">{content.brand.heroNote}</p>
          <h1 id="hero-title">{content.brand.name}</h1>
          <p className="tagline">{content.brand.tagline}</p>

          <div className="heroActions">
            <a href="#menu">View Menu</a>
            <a href="#visit">Find Us</a>
          </div>
        </div>

        <a className="scrollHint" href="#about" aria-label="Scroll to About">
          ↓
        </a>
      </section>

      <section
        id="about"
        className={
          displayMedia.about
            ? 'section shell aboutSection'
            : 'section shell aboutSection aboutSectionWithoutMedia'
        }
      >
        {displayMedia.about && (
          <div className="aboutMedia">
            <Image
              src={mediaSrc(displayMedia.about)}
              alt={displayMedia.about.alt}
              fill
              sizes="(max-width: 900px) 100vw, 45vw"
              style={{ objectPosition: objectPosition(displayMedia.about) }}
            />
          </div>
        )}

        <div className="aboutContent">
          <p className="sectionKicker">Who we are</p>
          <h2>{content.about.title}</h2>

          <div className="copy">
            {content.about.paragraphs.map((paragraph) => (
              <p key={paragraph}>{paragraph}</p>
            ))}

            <div className="featureGrid">
              {content.about.features.map((feature) => (
                <article className="featureCard" key={feature.title}>
                  <span className="featureIcon" aria-hidden="true">
                    {feature.icon}
                  </span>
                  <h3>{feature.title}</h3>
                  <p>{feature.text}</p>
                </article>
              ))}
            </div>
          </div>
        </div>
      </section>

      <section id="menu" className="section">
        <div className="shell">
          <div className="sectionHeading">
            <p className="sectionKicker">Good things to order</p>
            <h2>The Menu</h2>
            <p>{content.menuNote}</p>
          </div>

          <div className="menuGrid">
            {menu.categories.map((category) => (
              <article key={category.id} className="menuCategory">
                <h3>{category.name}</h3>
                <div>
                  {category.items.map((item) => (
                    <div className="menuItem" key={item.id}>
                      <div>
                        <h4>{item.name}</h4>
                        <p>{item.description}</p>
                      </div>
                      <strong>{formatMoney(item.price)}</strong>
                    </div>
                  ))}
                </div>
              </article>
            ))}
          </div>
        </div>
      </section>

      {displayMedia.gallery.length > 0 && (
        <section id="gallery" className="section gallerySection">
          <div className="shell">
            <div className="sectionHeading">
              <p className="sectionKicker">A peek inside</p>
              <h2>Gallery</h2>
            </div>
            <Gallery assets={displayMedia.gallery} />
          </div>
        </section>
      )}

      {reviewData.reviews.length > 0 && (
        <section id="reviews" className="section reviewsSection">
          <div className="shell">
            <div className="sectionHeading">
              <p className="sectionKicker">Kind words</p>
              <h2>What People Say</h2>
            </div>

            <div className="reviewsGrid">
              {reviewData.reviews.map((review) => (
                <article className="reviewCard" key={review.id}>
                  <div
                    className="reviewStars"
                    role="img"
                    aria-label={`${review.rating} out of 5 stars`}
                  >
                    <span aria-hidden="true">
                      {'★'.repeat(review.rating)}
                      {'☆'.repeat(5 - review.rating)}
                    </span>
                  </div>
                  <blockquote>“{review.body}”</blockquote>
                  <p className="reviewAuthor">— {review.authorName}</p>
                </article>
              ))}
            </div>
          </div>
        </section>
      )}

      <section id="visit" className="section visitSection">
        <div className="shell">
          <div className="sectionHeading">
            <p className="sectionKicker">Come say hi</p>
            <h2>Visit Us</h2>
          </div>

          <div className="visitGrid">
            {contact.mapEmbedUrl && (
              <iframe
                className="mapFrame"
                src={contact.mapEmbedUrl}
                loading="lazy"
                title={`${content.brand.name} location`}
              />
            )}

            <div className="visitDetails">
              <div className="visitBlock">
                <h3>📍 Address</h3>
                <p>{contact.address}</p>
              </div>

              <div className="visitBlock">
                <h3>🕒 Opening Hours</h3>
                <div className="hoursList">
                  {contact.hours.map((hour) => (
                    <div className="hoursRow" key={hour.day}>
                      <span>{hour.day}</span>
                      <span>{hour.time}</span>
                    </div>
                  ))}
                </div>
              </div>

              <div className="visitBlock">
                <h3>📞 Contact</h3>
                <p>
                  <a href={`tel:${contact.phone.replace(/[^\d+]/g, '')}`}>
                    {contact.phone}
                  </a>
                  <br />
                  <a href={`mailto:${contact.email}`}>{contact.email}</a>
                </p>
              </div>
            </div>
          </div>
        </div>
      </section>

      <footer>
        <div className="shell footerInner">
          <div className="footerBrand">{content.brand.name}</div>

          {contact.socialLinks.length > 0 && (
            <div className="footerSocials" aria-label="Social links">
              {contact.socialLinks.map((link) => (
                <a
                  key={link.platform}
                  href={link.url}
                  target="_blank"
                  rel="noopener noreferrer"
                  aria-label={link.platform}
                  title={link.platform}
                >
                  {socialIcon(link.platform)}
                </a>
              ))}
            </div>
          )}

          <p>
            © {new Date().getFullYear()} {content.brand.name}. All rights reserved.
          </p>
          <p className="footerCredit">
            <a href="mailto:eranthikah999@gmail.com">Site crafted by Hari</a>
          </p>
        </div>
      </footer>

      {whatsAppUrl && (
        <a
          className="whatsappFloat"
          href={whatsAppUrl}
          target="_blank"
          rel="noopener noreferrer"
          aria-label="Order on WhatsApp"
        >
          <svg viewBox="0 0 32 32" aria-hidden="true">
            <path d="M16.04 3C9.02 3 3.32 8.7 3.32 15.72c0 2.24.59 4.43 1.71 6.36L3.2 29l7.1-1.86a12.66 12.66 0 0 0 5.73 1.38h.01c7.01 0 12.72-5.7 12.72-12.72S23.05 3 16.04 3zm0 23.4h-.01a10.6 10.6 0 0 1-5.4-1.48l-.39-.23-4.21 1.1 1.12-4.1-.25-.42a10.62 10.62 0 0 1-1.63-5.65c0-5.86 4.77-10.63 10.64-10.63a10.6 10.6 0 0 1 10.63 10.64c0 5.86-4.77 10.63-10.63 10.63zm5.83-7.96c-.32-.16-1.89-.93-2.18-1.04-.29-.11-.5-.16-.72.16-.21.32-.82 1.04-1.01 1.25-.19.21-.37.24-.69.08-.32-.16-1.35-.5-2.57-1.59-.95-.85-1.59-1.9-1.78-2.22-.19-.32-.02-.49.14-.65.14-.14.32-.37.48-.56.16-.19.21-.32.32-.53.11-.21.05-.4-.03-.56-.08-.16-.72-1.73-.98-2.37-.26-.62-.52-.54-.72-.55h-.61c-.21 0-.56.08-.85.4-.29.32-1.12 1.09-1.12 2.66s1.15 3.08 1.31 3.29c.16.21 2.25 3.44 5.45 4.82.76.33 1.36.53 1.82.67.77.24 1.46.21 2.01.13.61-.09 1.89-.77 2.16-1.52.27-.75.27-1.39.19-1.52-.08-.13-.29-.21-.61-.37z" />
          </svg>
        </a>
      )}
    </main>
  );
}

function socialIcon(platform: string): string {
  switch (platform.toLowerCase()) {
    case 'instagram':
      return '📸';
    case 'facebook':
      return '👍';
    case 'tiktok':
      return '🎵';
    default:
      return '↗';
  }
}
